#!/usr/bin/env bash

# run-sidekiq.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

source bootstrap-script.sh
cd $RAILS_DIR
mkdir -p log
exec /sbin/setuser $DORA_USER bundle exec sidekiq -e $PASSENGER_APP_ENV > log/sidekiq.log
