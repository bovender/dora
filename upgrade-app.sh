#!/bin/bash
if [[ $(id -u -n) != app ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as 'app'..."
  exec setuser app $0
fi
set -e -x
cd $APP_DIR
bundle install
bundle exec rails db:migrate
bundle exec rails assets:precompile
passenger-config restart-app $APP_DIR

