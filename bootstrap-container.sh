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

date --rfc-3339=seconds > $FLAG_FILE
echo "Bootstrapping container... $(date --rfc-3339=seconds)"
set -x -e

git clone --depth 1 -b $GIT_BRANCH https://${GIT_USER}${GIT_USER:+:}${GIT_PASS}${GIT_USER:+@}${GIT_REPO} $APP_DIR
chown -R app:app ${APP_DIR}

chown -R app:app /shared
mkdir -p /shared/{bundle,log}
ln -sf /shared/bundle vendor/bundle &&\
ln -sf /shared/log log

cd $APP_DIR
setuser app bundle config set deployment true
setuser app bundle config set with production
setuser app bundle config set without test:development
setuser app bundle install
setuser app bundle exec rails db:migrate
setuser app bundle exec rails assets:precompile

set +x
echo "Done bootstrapping!.       $(date --rfc-3339=seconds)"
