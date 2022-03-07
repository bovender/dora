#!/bin/bash

# restart-app.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

source /etc/container_environment.sh
echo "# dora restarting Rails app in $RAILS_DIR..."
passenger-config restart-app $RAILS_DIR
