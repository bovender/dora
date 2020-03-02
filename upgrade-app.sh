#!/bin/bash
if [[ $(id -u -n) != app ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as 'app'..."
  exec setuser app $0
fi
set -x
APP_DIR=/home/app/app
cd $APP_DIR
PREVIOUS_VERSION=$(git describe 2>/dev/null || git rev-parse HEAD)
(
  git pull &&\
  bundle install &&\
  yarn install --check-files &&\
  bundle exec rails db:migrate &&\
  bundle exec rails assets:precompile &&\
  passenger-config restart-app $APP_DIR
) || (
  set +x
  echo "***** UPGRADE FAILED! *****"
  echo "Rolling back to $PREVIOUS_VERSION"
  set -x
  git reset --hard $PREVIOUS_VERSION
)
