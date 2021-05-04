#!/bin/bash

# Ensures that a host 'host.docker.internal' is known to the system and
# the host name resolves to the host of Docker container.
# From https://dev.to/hint/rails-system-tests-in-docker-4cj1

: ${HOST_DOMAIN:="host.docker.internal"}
function check_host { ping -q -c1 $HOST_DOMAIN > /dev/null 2>&1; }

if ! check_host; then
  HOST_IP=$(ip route | awk 'NR==1 {print $3}')
  echo "$HOST_IP $HOST_DOMAIN" >> /etc/hosts
fi
