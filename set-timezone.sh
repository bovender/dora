#!/usr/bin/env bash

# set-timezone.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

if [ "$TIMEZONE" != "" ]; then
  echo "# dora setting time zone to $TIMEZONE"
  ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
fi
