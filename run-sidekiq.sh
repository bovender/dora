#!/usr/bin/env bash

# run-sidekiq.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

APP_DIR=/home/app/rails
cd $APP_DIR
exec /sbin/setuser app bundle exec sidekiq -e $PASSENGER_APP_ENV > log/sidekiq.log
