#!/usr/bin/env bash

if [ "$TIMEZONE" != "" ]; then
  echo "Setting time zone to $TIMEZONE"
  ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
fi
