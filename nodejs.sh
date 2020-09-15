#!/bin/bash

# nodejs.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

set -e
source /pd_build/buildconfig
set -x

echo "# dora enabling NodeSource APT repo"
CODENAME=$(lsb_release -c -s)
run curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -
echo "deb https://deb.nodesource.com/node_10.x $CODENAME main" > /etc/apt/sources.list.d/nodesource.list
echo "deb-src https://deb.nodesource.com/node_10.x $CODENAME main" >> /etc/apt/sources.list.d/nodesource.list && apt-get update

## Install Node.js (also needed for Rails asset compilation)
minimal_apt_get_install nodejs
echo "# Updating npm"
run npm update npm -g
if [[ ! -e /usr/bin/node ]]; then
	ln -s /usr/bin/nodejs /usr/bin/node
fi
