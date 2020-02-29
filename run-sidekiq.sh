cd $APP_DIR
exec /sbin/setuser app bundle exec sidekiq > /shared/log/sidekiq.log
