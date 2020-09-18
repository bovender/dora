#!/bin/bash

# restart-app.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

APP_DIR=/home/dora/rails
echo "# dora restarting Rails app in $APP_DIR..."
passenger-config restart-app $APP_DIR
