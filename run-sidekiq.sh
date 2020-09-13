#!/usr/bin/env bash
cd /home/app/rails
exec /sbin/setuser app bundle exec sidekiq -e $PASSENGER_APP_ENV > /home/app/rails/log/sidekiq.log
