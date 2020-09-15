#!/bin/bash

# upgrade-app.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

echo "# dora app upgrade script"

if [[ $(id -u -n) != app ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as 'app'..."
  exec setuser app $0
fi

APP_DIR=/home/app/rails
LOCK_PRIMARY=/upgrade-lock.primary
LOCK_SECONDARY=/upgrade-lock.secondary
WAIT_SECONDS=60
WAIT_INTERVAL=10
E_UPGRADE_LOCKED=1

# Check if an upgrade is currently in progress.
# When pushing and pushing --tags to the main branch, the web hook will be
# executed twice in short succession. We use two lock files to deal with this
# situation. If there is one lock file present, the script waits for a while
# before upgrading in order to be able to pull the latest tags. If there are
# two lock files, we bail out immediately.
function check_lock {
  if [[ ! -f $LOCK_PRIMARY ]]; then
    touch $LOCK_PRIMARY || echo "WARNING: Unable to create primary lock file!"
  elif [[ -f $LOCK_SECONDARY ]]; then
    exit 0
  else
    # Primary lock present, but secondary lock not: set secondary lock and wait
    touch $LOCK_SECONDARY || echo "WARNING: Unable to create secondary lock file!"
    WAITING=0
    while [[ -f $LOCK_PRIMARY ]] && (( $WAITING <= $WAIT_SECONDS )); do
      (( WAITING = WAITING + WAIT_INTERVAL ))
      sleep $WAIT_INTERVAL
    done
    rm $LOCK_SECONDARY || echo "WARNING: Unable to remove secondary lock file!"
    # If the primary lock is still present after waiting politely, then quit
    if [[ -f $LOCK_PRIMARY ]]; then
      echo "ERROR: Upgrade still locked after waiting $WAIT_SECONDS seconds, exiting!"
      exit $E_UPGRADE_LOCKED
    fi
  fi
}

function release_lock {
  if [[ -f $LOCK_SECONDARY ]]; then
    rm $LOCK_SECONDARY || echo "WARNING: Unable to remove secondary lock file!"
  elif [[ -f $LOCK_PRIMARY ]]; then
    rm $LOCK_PRIMARY || echo "WARNING: Unable to remove primary lock file!"
  else
    echo "WARNING: Did not find any lock file?!"
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
  passenger-config restart-app $APP_DIR
}

function rollback {
  set +x
  echo "***** UPGRADE FAILED! *****"
  echo "Rolling back to $PREVIOUS_VERSION"
  set -x
  git reset --hard $PREVIOUS_VERSION
}

check_lock
set -x
cd $APP_DIR
PREVIOUS_VERSION=$(git describe 2>/dev/null || git rev-parse HEAD)
pull && (upgrade || rollback)
RESULT=$?
set +x
release_lock
exit $RESULT
