#!/usr/bin/env bash

# bootstrap-script.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

# Provides a common ground for all utility scripts.

source /etc/container_environment.sh

if [[ -z $DORA_USER ]]; then
  echo "FATAL: \$DORA_USER environment variable is not set."
  echo "FATAL: The script will not work."
  echo "FATAL: One possible explanation is if you have a docker-compose.yml file"
  echo "FATAL: that declares the DORA_USER environment variable but does not set"
  echo "FATAL: it and if your .env file also does not set this variable, in which"
  echo "FATAL: case the default values from dora's dockerfile will not be used,"
  echo "FATAL: leaving empty variables."
  exit 1
fi
