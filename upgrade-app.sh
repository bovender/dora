#!/bin/bash

# upgrade-app.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

if [[ $(id -u -n) != dora ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as 'dora'..."
  echo
  exec setuser dora $0
fi

echo "# dora app upgrade script"

APP_DIR=/home/dora/rails
LOCK_PRIMARY=/home/dora/upgrade-lock.primary
LOCK_SECONDARY=/home/dora/upgrade-lock.secondary
WAIT_SECONDS=300
WAIT_INTERVAL=30
E_UPGRADE_LOCKED=1

if [[ -z $RAILS_ENV ]]; then
  echo "WARNING: \$RAILS_ENV is empty! This is probably not what you want."
  echo "WARNING: \$PASSENGER_APP_ENV=$PASSENGER_APP_ENV"
fi

# Check if an upgrade is currently in progress.
# When pushing and pushing --tags to the main branch, the web hook will be
# executed twice in short succession. We use two lock files to deal with this
# situation. If there is one lock file present, the script waits for a while
# before upgrading in order to be able to pull the latest tags. If there are
# two lock files, we bail out immediately.
function check_lock {
  if [[ ! -f $LOCK_PRIMARY ]]; then
    MY_LOCK=$LOCK_PRIMARY
    touch $LOCK_PRIMARY || echo "WARNING: Unable to create primary lock file!"
  elif [[ -f $LOCK_SECONDARY ]]; then
    echo "FATAL: Two lock files present -- not attempting to upgrade the app!"
    echo "FATAL: Lock file 1: $LOCK_PRIMARY"
    echo "FATAL: Lock file 2: $LOCK_SECONDARY"
    echo "FATAL: If this is an error, remove the lock files manually."
    exit 0
  else
    # Primary lock present, but secondary lock not: set secondary lock and wait
    MY_LOCK=$LOCK_SECONDARY
    touch $LOCK_SECONDARY || echo "WARNING: Unable to create secondary lock file!"
    echo "INFO: Another upgrade is in progress, waiting at most $WAIT_SECONDS seconds..."
    echo -n "INFO: "
    WAITING=0
    while [[ -f $LOCK_PRIMARY ]] && (( $WAITING < $WAIT_SECONDS )); do
      (( WAITING = WAITING + WAIT_INTERVAL ))
      echo -n "$WAITING... "
      sleep $WAIT_INTERVAL
    done
    echo
    rm $LOCK_SECONDARY 2>/dev/null || echo "WARNING: Unable to remove secondary lock file!"
    # Quit if the primary lock is still present after waiting politely
    if [[ -f $LOCK_PRIMARY ]]; then
      echo "FATAL: Upgrade still locked after waiting $WAITING seconds, exiting!"
      echo "FATAL: If you think this is an error, remove the lock file manually:"
      echo "FATAL: rm $LOCK_PRIMARY"
      exit $E_UPGRADE_LOCKED
    fi
  fi
}

function release_lock {
  if [[ -f $MY_LOCK ]]; then
    rm $MY_LOCK || echo "WARNING: Unable to remove my lock file!"
  fi
}

function pull {
  # GIT_PULL is a global configuration flag of dora
  if [ "$GIT_PULL" != "false" ]; then
    git pull
  fi
}

function upgrade {
  bundle install &&\
  yarn install --check-files &&\
  bundle exec rails db:migrate &&\
  bundle exec rails assets:precompile &&\
  git describe --always > tmp/version &&\
  passenger-config restart-app $APP_DIR &&\
  set +x &&\
  echo -e "\n\n***** UPGRADE SUCCEEDED! :-) *****\n"
}

function rollback {
  set +x
  echo "***** UPGRADE FAILED! :-( *****"
  echo "Rolling back to $PREVIOUS_VERSION"
  set -x
  git reset --hard $PREVIOUS_VERSION
}

check_lock
set -x
cd $APP_DIR
PREVIOUS_VERSION=$(git describe 2>/dev/null || git rev-parse HEAD)
sv stop sidekiq
pull && (upgrade || rollback)
sv start sidekiq
set +x
release_lock
