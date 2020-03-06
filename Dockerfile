# See https://github.com/phusion/passenger-docker
FROM phusion/passenger-ruby26:1.0.9

ARG PUBLIC_KEY="unusable.pub"
ENV APP_NAME "app"
ENV GIT_USER ""
ENV GIT_PASS ""
ENV GIT_REPO ""
ENV GIT_BRANCH "master"
ENV GIT_PULL "true"
ENV SECRET_KEY_BASE ""
ENV RAILS_PRECOMPILE_ASSETS "true"
ENV RAILS_SMTP_HOST ""
ENV RAILS_SMTP_USER ${APP_NAME}
ENV RAILS_SMTP_PASS ""
ENV RAILS_DB_HOST ""
ENV RAILS_DB_NAME ${APP_NAME}
ENV RAILS_DB_USER ${APP_NAME}
ENV RAILS_DB_PASS ""

# Install nodejs in passenger-docker's way
RUN mkdir /pd_build
ADD nodejs.sh /pd_build
ADD buildconfig /pd_build
RUN /pd_build/nodejs.sh

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list &&\
    apt-get update && apt-get install yarn

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

ADD dora-banner.sh /usr/local/bin/dora-banner.sh
RUN chmod +x /usr/local/bin/dora-banner.sh

RUN mkdir -p /etc/my_init.d
ADD bootstrap-container.sh /etc/my_init.d/10_bootstrap_container.sh
RUN chmod +x /etc/my_init.d/10_bootstrap_container.sh

RUN mkdir -p /etc/service/sidekiq
ADD run-sidekiq.sh /etc/service/sidekiq/run
RUN chmod +x /etc/service/sidekiq/run

# Install either the dummy SSH key or the configured one
ADD sshd_config /etc/sshd/sshd_config
RUN rm -f /etc/service/sshd/down &&\
    passwd -u app
ADD ${PUBLIC_KEY} /tmp/key.pub
RUN cat /tmp/key.pub >> /home/app/.ssh/authorized_keys &&\
    rm -f /tmp/key.pub &&\
    chown app:app /home/app/.ssh/authorized_keys &&\
    chmod 0700 /home/app/.ssh &&\
    chomd 0600 /home/app/.ssh/authorized_keys

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
