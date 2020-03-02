cd /home/app/app
exec /sbin/setuser app bundle exec sidekiq > /shared/log/sidekiq.log
