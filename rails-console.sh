#!/bin/bash

# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

source bootstrap-script.sh
if [[ $(id -u -n) != $DORA_USER ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking as '$DORA_USER'..."
  echo
  exec setuser $DORA_USER $0
fi

echo "# dora console helper for Rails"
echo "# PASSENGER_APP_ENV=$PASSENGER_APP_ENV"
echo "# Launching Rails console in $RAILS_DIR, please wait..."
cd $RAILS_DIR
bin/rails c -e $PASSENGER_APP_ENV
