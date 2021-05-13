#!/usr/bin/env bash

# run-sidekiq.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

APP_DIR=/home/dora/rails
cd $APP_DIR
mkdir -p log
exec /sbin/setuser dora bundle exec sidekiq -e $PASSENGER_APP_ENV > log/sidekiq.log
