# See https://github.com/phusion/passenger-docker
FROM phusion/passenger-ruby30:2.1.0

ARG PUBLIC_KEY="unusable_pub"
ARG DORA_USER="dora"
ENV DORA_USER ${DORA_USER}
ARG DORA_UID=1000
ENV DORA_UID ${DORA_UID}
ARG DORA_GID=1000
ENV DORA_GID ${DORA_GID}
ENV APP_NAME "rails"
ENV RAILS_DIR "/home/$DORA_USER/rails"
ENV GIT_USER ""
ENV GIT_PASS ""
ENV GIT_REPO ""
ENV GIT_BRANCH "main"
ENV GIT_PULL "true"
ENV SECRET_KEY_BASE ""
ENV WEBHOOK_SECRET ""
ENV RAILS_PRECOMPILE_ASSETS "true"
ENV RAILS_SMTP_HOST ""
ENV RAILS_SMTP_USER ${APP_NAME}
ENV RAILS_SMTP_PASS ""
ENV RAILS_SMTP_FROM ""
ENV RAILS_DB_HOST ""
ENV RAILS_DB_NAME ${APP_NAME}
ENV RAILS_DB_USER ${APP_NAME}
ENV RAILS_DB_PASS ""
ENV EMAIL_REPORTS_TO ""
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
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update &&\
    apt-get install -y --no-install-recommends \
    imagemagick \
    msmtp \
    shared-mime-info \
    sudo \
    tzdata \
    yarn \
    vim && \
    apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Upstream configures an `app` user and group.
# In order to avoid confusion with folder names (every rails app has a folder
# named `app`), we rename the user and group to `dora` by default; this can be
# configured with arguments to the `docker build` command. In addition, we
# grant passwordless sudoer rights to the container user.
RUN groupmod -n $DORA_USER -g $DORA_GID app && \
    usermod -l $DORA_USER -u $DORA_UID -g $DORA_GID -m -d /home/$DORA_USER app && \
    usermod -p "*" $DORA_USER && \
    usermod -aG sudo $DORA_USER && \
    usermod -aG docker_env $DORA_USER && \
    echo "$DORA_USER ALL=NOPASSWD: ALL" >> /etc/sudoers.d/50-$DORA_USER

# ENV HOME /root
WORKDIR /home/$DORA_USER

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD rails.conf /etc/nginx/sites-enabled/rails.conf
RUN sed -i "s/DORA_USER_WILL_BE_REPLACED_BY_DOCKERFILE/$DORA_USER/g" /etc/nginx/sites-enabled/rails.conf
ADD rails-env.conf /etc/nginx/main.d/rails-env.conf

RUN gem install bundler

ADD upgrade-app.sh /usr/local/bin/upgrade-app.sh
RUN chmod +x /usr/local/bin/upgrade-app.sh

ADD restart-app.sh /usr/local/bin/restart-app.sh
RUN chmod +x /usr/local/bin/restart-app.sh

ADD rails-console.sh /usr/local/bin/rails-console.sh
RUN chmod +x /usr/local/bin/rails-console.sh

ADD dora-banner.sh /usr/local/bin/dora-banner.sh
RUN chmod +x /usr/local/bin/dora-banner.sh

ADD configure-msmtp.sh /usr/local/bin/configure-msmtp.sh
RUN chmod +x /usr/local/bin/configure-msmtp.sh

ADD dora-status.sh /usr/local/bin/dora-status.sh
RUN chmod +x /usr/local/bin/dora-status.sh

ADD send-dora-status-mail.sh /usr/local/bin/send-dora-status-mail.sh
RUN chmod +x /usr/local/bin/send-dora-status-mail.sh

RUN mkdir -p /etc/my_init.d
ADD bootstrap-container.sh /etc/my_init.d/10_bootstrap_container.sh
RUN chmod +x /etc/my_init.d/10_bootstrap_container.sh
ADD install-wkhtmltopdf.sh /etc/my_init.d/90_install_wkhtmltopdf.sh
RUN chmod +x /etc/my_init.d/90_install_wkhtmltopdf.sh
ADD set-timezone.sh /etc/my_init.d/01_set_timezone.sh
RUN chmod +x /etc/my_init.d/01_set_timezone.sh
ADD set-host-docker-internal.sh /etc/my_init.d/02_set_host_docker_internal.sh
RUN chmod +x /etc/my_init.d/02_set_host_docker_internal.sh
RUN mkdir -p /etc/service/sidekiq
ADD run-sidekiq.sh /etc/service/sidekiq/run
RUN chmod +x /etc/service/sidekiq/run

ADD logrotate-logs /etc/logrotate.d/logs
RUN sed -i "s/DORA_USER_WILL_BE_REPLACED_BY_DOCKERFILE/$DORA_USER/g" /etc/logrotate.d/logs
RUN chmod 0644 /etc/logrotate.d/logs

# Install either the dummy SSH key or the configured one and unlock the $DORA_USER
ADD sshd_config /etc/ssh/sshd_config
RUN rm -f /etc/service/sshd/down &&\
    passwd -u $DORA_USER
ADD ${PUBLIC_KEY} /tmp/key.pub
RUN cat /tmp/key.pub >> /home/$DORA_USER/.ssh/authorized_keys &&\
    rm -f /tmp/key.pub &&\
    chown $DORA_USER:$DORA_USER /home/$DORA_USER/.ssh/authorized_keys &&\
    chmod 0700 /home/$DORA_USER/.ssh &&\
    chmod 0600 /home/$DORA_USER/.ssh/authorized_keys

# Setting the PATH variable via /etc/container_environment does not work;
# see 
RUN echo "PATH=/home/$DORA_USER/rails/bin:\$PATH" >> /home/$DORA_USER/.profile

# USER $DORA_USER
WORKDIR /home/$DORA_USER/rails
