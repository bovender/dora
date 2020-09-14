# See https://github.com/phusion/passenger-docker
FROM phusion/passenger-ruby27:1.0.11

ARG PUBLIC_KEY="unusable_pub"
ENV APP_NAME "rails"
ENV GIT_USER ""
ENV GIT_PASS ""
ENV GIT_REPO ""
ENV GIT_BRANCH "master"
ENV GIT_PULL "true"
ENV SECRET_KEY_BASE ""
ENV WEBHOOK_SECRET ""
ENV RAILS_PRECOMPILE_ASSETS "true"
ENV RAILS_SMTP_HOST ""
ENV RAILS_SMTP_USER ${APP_NAME}
ENV RAILS_SMTP_PASS ""
ENV RAILS_DB_HOST ""
ENV RAILS_DB_NAME ${APP_NAME}
ENV RAILS_DB_USER ${APP_NAME}
ENV RAILS_DB_PASS ""
ENV TIMEZONE="UCT"
ENV WKHTMLTOPDF ""
ENV WKHTMLTOPDF_URL "https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.bionic_amd64.deb"
ENV WKHTMLTOPDF_SUM "db48fa1a043309c4bfe8c8e0e38dc06c183f821599dd88d4e3cea47c5a5d4cd3"

# Install nodejs in passenger-docker's way
RUN mkdir /pd_build
ADD nodejs.sh /pd_build
ADD buildconfig /pd_build
RUN /pd_build/nodejs.sh

# Install yarn and other packages
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list &&\
    apt-get update &&\
    apt-get install -y --no-install-recommends imagemagick tzdata yarn

ENV HOME /root
WORKDIR /home/app

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD rails.conf /etc/nginx/sites-enabled/rails.conf
ADD rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN gem install bundler

ADD upgrade-app.sh /usr/local/bin/upgrade-app.sh
RUN chmod +x /usr/local/bin/upgrade-app.sh

ADD upgrade-app.sh /usr/local/bin/restart-app.sh
RUN chmod +x /usr/local/bin/restart-app.sh

ADD upgrade-app.sh /usr/local/bin/rails-console.sh
RUN chmod +x /usr/local/bin/rails-console.sh

ADD dora-banner.sh /usr/local/bin/dora-banner.sh
RUN chmod +x /usr/local/bin/dora-banner.sh

RUN mkdir -p /etc/my_init.d
ADD bootstrap-container.sh /etc/my_init.d/10_bootstrap_container.sh
RUN chmod +x /etc/my_init.d/10_bootstrap_container.sh
ADD install-wkhtmltopdf.sh /etc/my_init.d/90_install_wkhtmltopdf.sh
RUN chmod +x /etc/my_init.d/90_install_wkhtmltopdf.sh
ADD set-timezone.sh /etc/my_init.d/01_set_timezone.sh
RUN chmod +x /etc/my_init.d/01_set_timezone.sh

RUN mkdir -p /etc/service/sidekiq
ADD run-sidekiq.sh /etc/service/sidekiq/run
RUN chmod +x /etc/service/sidekiq/run

ADD logrotate-logs /etc/logrotate.d/logs
RUN chmod 0644 /etc/logrotate.d/logs

# Install either the dummy SSH key or the configured one
ADD sshd_config /etc/ssh/sshd_config
RUN rm -f /etc/service/sshd/down &&\
    passwd -u app
ADD ${PUBLIC_KEY} /tmp/key.pub
RUN cat /tmp/key.pub >> /home/app/.ssh/authorized_keys &&\
    rm -f /tmp/key.pub &&\
    chown app:app /home/app/.ssh/authorized_keys &&\
    chmod 0700 /home/app/.ssh &&\
    chmod 0600 /home/app/.ssh/authorized_keys

# Clean up APT when done.
# RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/app/rails
