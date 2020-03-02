#!/bin/bash
# This script serves to boostrap the container.
# This script is run every time the container is started,
# but we do not want to re-compile the assets over and
# over again and so on, so we use a flag file to determine
# whether the container has already been bootstrapped or not.
# Bootstrapping could be done by an external script (see
# Discourse's launcher script for instance), but we prefer
# to have all the tools that we need in the container
# itself, without a need for an external control script.
FLAG_FILE=/bootstrapped
if [ -a $FLAG_FILE ]; then
  DATE=$(cat $FLAG_FILE)
  echo "This container has already been bootstrapped on $DATE."
  exit
fi

echo "Bootstrapping container... $(date --rfc-3339=seconds)"
APP_DIR=/home/app/app
echo "Application directory:     $APP_DIR"
set -x -e

git clone --depth 1 -b $GIT_BRANCH https://${GIT_USER%% }${GIT_USER:+:}${GIT_PASS%% }${GIT_USER:+@}${GIT_REPO#https://} "$APP_DIR" ||
	(echo "Directory `$APP_DIR` exists already, attempting to pull..."; git -C "$APP_DIR" pull)
chown -R app:app $APP_DIR
chown -R app:app /shared

# NB: When invoked with the `-p` flag, mkdir will not
# raise an error if the directory exists already.
# We keep gems and node modules out of the container
# for faster rebuilding.
mkdir -p /shared/{bundle,log,node_modules,uploads}

cd $APP_DIR
rm -rf vendor/bundle && ln -s /shared/bundle vendor/bundle
for d in log node_modules uploads; do
  rm -rf $d
  ln -s /shared/$d $d
done
setuser app bundle config set deployment true
setuser app bundle config set with production
setuser app bundle config set without test:development
setuser app bundle install
setuser app bundle exec rails db:migrate
setuser app yarn install --check-files
setuser app bundle exec rails assets:precompile

set +x
echo "Done bootstrapping!.       $(date --rfc-3339=seconds)"
date --rfc-3339=seconds > $FLAG_FILE
