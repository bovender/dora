#!/usr/bin/env bash
cd /home/app/app
exec /sbin/setuser app bundle exec sidekiq > /home/app/app/log/sidekiq.log
