#!/bin/bash

# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

APP_DIR=/home/app/rails

echo "# dora console helper for Rails"
echo "# PASSENGER_APP_ENV=$PASSENGER_APP_ENV"
echo "# Launching Rails console in $APP_DIR, please wait..."
cd $APP_DIR
bin/rails c -e $PASSENGER_APP_ENV
