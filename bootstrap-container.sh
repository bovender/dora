#!/usr/bin/env bash

# bootstrap-container.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

source /etc/container_environment.sh
if [[ $(id -u -n) != $DORA_USER ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as '$DORA_USER'..."
  echo
  exec setuser $DORA_USER $0
fi

dora-banner.sh
dora-banner.sh | grep -v _PASS | sudo tee /etc/ssh/dora-banner >/dev/null

# This script is run every time the container is started, but we do not want to
# re-compile the assets over and over again and so on, so we use a flag file to
# determine whether the container has already been bootstrapped or not.
# Bootstrapping could be done by an external script (see Discourse's launcher
# script for instance), but we prefer to have all the tools that we need in the
# container itself, without a need for an external control script.
FLAG_FILE=/bootstrapped
if [ -a $FLAG_FILE ]; then
  DATE=$(cat $FLAG_FILE)
  echo "This container has already been bootstrapped on $DATE." | tee -a /etc/ssh/dora-banner
  exit
fi

echo "# Bootstrapping container... $(date --rfc-3339=seconds)"
set -x -e

# Make rails commands easily accessible from the command line.
# The modified PATH will be picked up by passenger-docker's my_init system.
# See: https://github.com/phusion/baseimage-docker#environment_variables
echo -e "${APP_DIR}/bin:$PATH" | sudo tee /etc/container_environment/PATH >/dev/null

configure-msmtp.sh --force
# Placing a script 'send-dora-status-mail' into /etc/cron.daily did not work
sudo sed -i '/begin dora jobs/,/end dora jobs/d' /etc/crontab
# MUST have real tab characters rather than spaces in front of the heredoc lines
cat <<-EOF | sudo tee -a /etc/crontab
	# begin dora jobs
	0 5 * * * root /bin/bash -l /usr/local/bin/send-dora-status-mail.sh
	# end dora jobs
	EOF

if [ "$GIT_PULL" != "false" ]; then
  git clone -b $GIT_BRANCH https://${GIT_USER%% }${GIT_USER:+:}${GIT_PASS%% }${GIT_USER:+@}${GIT_REPO#https://} "$RAILS_DIR" ||
  	(echo "# Directory `$RAILS_DIR` exists already, attempting to pull..."; git -C "$RAILS_DIR" pull)
fi

cd $RAILS_DIR

case $PASSENGER_APP_ENV in
  production)
    BUNDLE_WITH="production"
    BUNDLE_WITHOUT="test:development"
    BUNDLE_DEPLOY="true"
    ;;
  development|test)
    BUNDLE_WITH="development:test"
    BUNDLE_WITHOUT="production"
    BUNDLE_DEPLOY="false"
    ;;
esac

# If we do not clone and pull a repository, we can assume that
# the app directory has bene mounted into the container, in
# which case we do not need to link reusable directories to
# the outside world.
if [ "$GIT_PULL" == "false" ]; then
  set +x; echo "# Not pulling repository; not linking directories!"; set -x
else
  # NB: When invoked with the `-p` flag, mkdir will not
  # raise an error if the directory exists already.
  # We keep gems and node modules out of the container
  # for faster rebuilding.
  sudo mkdir -p /shared/{bundle,log,node_modules,uploads}
  for d in log node_modules uploads; do
    rm -rf $d
    ln -s /shared/$d $d
  done
  rm -rf vendor/bundle && ln -s /shared/bundle vendor/bundle
  sudo chown -R ${USER}:${USER} /shared
  sudo chown -R ${USER}:${USER} $RAILS_DIR
fi

export RAILS_ENV=$PASSENGER_APP_ENV
echo $RAILS_ENV | sudo tee /etc/container_environment/RAILS_ENV
sed -i '/^source \/etc\/profile/d' ${HOME}/.bashrc
echo 'source /etc/profile' >> ${HOME}/.bashrc
sed -i "/PS1='\[/d" ${HOME}/.bashrc
echo "PS1='[${APP_NAME:-(APP_NAME not set!)} ${RAILS_ENV:-(RAILS_ENV not set!)}]${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '" >> ${HOME}/.bashrc

# If there is no Gemfile (and we are told not to clone or pull a repository),
# assume that this is a new application or plugin in development, and exit.
if [ "$GIT_PULL" == "false" -a ! -f Gemfile ]; then
  echo "# No Gemfile was found and were are not going to clone a repository."
  echo "# Exiting gracefully to allow setting up a new Rails application."
  echo "# NB: Rails will no install a new app in the current directory if this"
  echo "# directory is called `rails`. Therefore, you may want to create the"
  echo "# app in the home directory, and then move it into the correct place:"
  echo "#"
  echo "#     $ cd ${HOME}"
  echo "#     $ rails new my_new_app"
  echo "#     $ mv my_new_app/* rails/"
  echo "#     $ rm -r my_new_app"
  echo "#"
  echo "# On your *development machine*, you will probably need to change the"
  echo "# ownership of the files:"
  echo "#"
  echo "#     me@my-dev-machine:~/code/my_new_app$ sudo chown -R me:9999 *"
  exit 0
fi

bundle config --local path vendor/bundle
bundle config --local deployment $BUNDLE_DEPLOY
bundle config --delete without
bundle config --local with $BUNDLE_WITH
bundle config --local without $BUNDLE_WITHOUT
bundle install
yarn install --check-files
bundle exec rails db:migrate

if [ "$RAILS_PRECOMPILE_ASSETS" == "true" ]; then
  bundle exec rails assets:precompile
fi

set +e
git describe --always > tmp/version

set +x
echo "# Done bootstrapping!        $(date --rfc-3339=seconds)" | sudo tee -a /etc/ssh/dora-banner
date --rfc-3339=seconds | sudo tee $FLAG_FILE >/dev/null
