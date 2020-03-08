#!/usr/bin/env bash

# This script serves to boostrap the container.
# This script is run every time the container is started, but we do not want to
# re-compile the assets over and over again and so on, so we use a flag file to
# determine whether the container has already been bootstrapped or not.
# Bootstrapping could be done by an external script (see Discourse's launcher
# script for instance), but we prefer to have all the tools that we need in the
# container itself, without a need for an external control script.

dora-banner.sh
dora-banner.sh | grep -v _PASS > /etc/ssh/dora-banner

FLAG_FILE=/bootstrapped
if [ -a $FLAG_FILE ]; then
  DATE=$(cat $FLAG_FILE)
  echo "This container has already been bootstrapped on $DATE." | tee -a /etc/ssh/dora-banner
  exit
fi

echo "= Bootstrapping container... $(date --rfc-3339=seconds)"
APP_DIR=/home/app/app
set -x -e

if [ "$GIT_PULL" != "false" ]; then
  git clone --depth 1 -b $GIT_BRANCH https://${GIT_USER%% }${GIT_USER:+:}${GIT_PASS%% }${GIT_USER:+@}${GIT_REPO#https://} "$APP_DIR" ||
  	(echo "= Directory `$APP_DIR` exists already, attempting to pull..."; git -C "$APP_DIR" pull)
fi

cd $APP_DIR

case $PASSENGER_APP_ENV in
  production)
    BUNDLE_WITHOUT="test:development"
    BUNDLE_DEPLOY="true"
    ;;
  development)
    BUNDLE_WITHOUT="test:production"
    BUNDLE_DEPLOY="false"
    ;;
  test)
    BUNDLE_WITHOUT="production:development"
    BUNDLE_DEPLOY="false"
    ;;
esac

# If we do not clone and pull a repository, we can assume that
# the app directory has bene mounted into the container, in
# which case we do not need to link reusable directories to
# the outside world.
if [ "$GIT_PULL" == "false" ]; then
  set +x; echo "= Not pulling repository; not linking directories!"; set -x
else
  # NB: When invoked with the `-p` flag, mkdir will not
  # raise an error if the directory exists already.
  # We keep gems and node modules out of the container
  # for faster rebuilding.
  mkdir -p /shared/{bundle,log,node_modules,uploads}
  for d in log node_modules uploads; do
    rm -rf $d
    ln -s /shared/$d $d
  done
  rm -rf vendor/bundle && ln -s /shared/bundle vendor/bundle
  chown -R app:app /shared
  chown -R app:app $APP_DIR
fi

setuser app bundle config set path vendor/bundle
setuser app bundle config set deployment $BUNDLE_DEPLOY
setuser app bundle config set with $PASSENGER_APP_ENV
setuser app bundle config set without $BUNDLE_WITHOUT
setuser app bundle install
setuser app yarn install --check-files
setuser app bundle exec rails db:migrate

if [ "$RAILS_PRECOMPILE_ASSETS" == "true" ]; then
  setuser app bundle exec rails assets:precompile
fi

set +e
setuser app git describe > tmp/version

set +x
echo "= Done bootstrapping!        $(date --rfc-3339=seconds)" | tee -a /etc/ssh/dora-banner
date --rfc-3339=seconds > $FLAG_FILE
