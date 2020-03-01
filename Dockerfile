# See https://github.com/phusion/passenger-docker
FROM phusion/passenger-ruby26:1.0.9

ENV APP_NAME "app"
ENV APP_DIR "/home/app/${APP_NAME}"
ENV RAILS_ENV "production"
ENV SECRET_KEY_BASE "SECRET_KEY_BASE must be defined"
ENV GIT_USER ""
ENV GIT_PASS ""
ENV GIT_REPO "GIT_REPO must be defined"
ENV GIT_BRANCH "master"
ENV RAILS_SMTP_HOST "RAILS_SMTP_HOST must be defined"
ENV RAILS_SMTP_USER ${APP_NAME}
ENV RAILS_SMTP_PASS "RAILS_SMTP_PASS must be defined"
ENV RAILS_DB_HOST "RAILS_DB_HOST must be defined"
ENV RAILS_DB_NAME ${APP_NAME}
ENV RAILS_DB_USER ${APP_NAME}
ENV RAILS_DB_PASS "RAILS_DB_PASS must be defined"

# This is from passenger-docker's README.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD app.conf /etc/nginx/sites-enabled/app.conf
ADD app-env.conf /etc/nginx/main.d/app-env.conf

RUN gem install bundler

ADD upgrade-app.sh /usr/local/bin/upgrade-app.sh
RUN chmod +x /usr/local/bin/upgrade-app.sh

RUN mkdir -p /etc/my_init.d
ADD bootstrap-container.sh /etc/my_init.d/10_bootstrap_container.sh
RUN chmod +x /etc/my_init.d/10_bootstrap_container.sh

RUN mkdir -p /etc/services/sidekiq
ADD run-sidekiq.sh /etc/services/sidekiq/run
RUN chmod +x /etc/services/sidekiq/run

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
