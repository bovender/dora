#!/usr/bin/env bash

# install-wkhtmltopdf.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

echo "# dora wkhtmltopdf installation script"

DEST_FILE=/tmp/wkhtmltopdf.deb

if [ $(id -u) -ne 0 ]; then
  echo "This script must be run as root. It serves to install wkhtmltopdf."
  exit 1
fi

if which wkhtmltopdf; then
  echo "wkhtmltopdf already installed: at $(which wkhtmltpdf)"
  wkhtmltopdf -V
  exit 0
fi

if [ "$NO_WKHTMLTOPDF" != "" ]; then
  echo "\`\$NO_WKHTMLTOPDF\` is set to $NO_WKHTMLTOPDF"
  echo "Will not install wkhtmltopdf."
  exit 0
fi

echo "wkhtmltopdf not found..."
if [ -f $DEST_FILE ]; then
  echo "... but there is $DEST_FILE"
else
  echo "... attempting to download from $WKHTMLTOPDF_URL"
  set -x -e
  curl -L -s "$WKHTMLTOPDF_URL" -o $DEST_FILE
fi

echo "$WKHTMLTOPDF_SUM  $DEST_FILE" | sha256sum -c

apt-get update
dpkg -i $DEST_FILE || apt-get install -f -y --no-install-recommends
