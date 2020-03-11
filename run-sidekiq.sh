#!/usr/bin/env bash
cd /home/app/app
exec /sbin/setuser app bundle exec sidekiq -e $PASSENGER_APP_ENV > /home/app/app/log/sidekiq.log
