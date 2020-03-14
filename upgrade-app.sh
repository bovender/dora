#!/bin/bash
if [[ $(id -u -n) != app ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as 'app'..."
  exec setuser app $0
fi

function pull {
  if [ "$GIT_PULL" != "false" ]; then
    git pull
   fi
}

function upgrade {
  bundle install &&\
  yarn install --check-files &&\
  bundle exec rails db:migrate &&\
  bundle exec rails assets:precompile &&\
  git describe --always > tmp/version &&\
  passenger-config restart-app $APP_DIR
}

function rollback {
  set +x
  echo "***** UPGRADE FAILED! *****"
  echo "Rolling back to $PREVIOUS_VERSION"
  set -x
  git reset --hard $PREVIOUS_VERSION
}

set -x
APP_DIR=/home/app/app
cd $APP_DIR
PREVIOUS_VERSION=$(git describe 2>/dev/null || git rev-parse HEAD)
pull && (upgrade || rollback)
