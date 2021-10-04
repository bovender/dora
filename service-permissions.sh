#!/usr/bin/env bash

# servide-permissions.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

# Adjust runit's service permissions for sidekiq so that it can be stopped and
# restarted by the 'dora' group.
cd /etc/service/sidekiq
chgrp -R dora *
chmod g+rw -R *
