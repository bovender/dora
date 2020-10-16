#!/usr/bin/env bash

# configure-msmtp.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora


echo "# dora configuring msmtp"
MSMTPRC=/etc/msmtprc

if [[ $(id -u) != 0 ]]; then
  echo "Script was invoked by user '$(id -u -n)'; re-invoking with sudo..."
  echo
  sudo $0
fi

function show_help() {
  echo "Usage: $(basename $0) [options]"
  echo "Options:"
  echo "  -f, --force: Force configuration even if $MSMTPRC exists"
  echo "  -h, --help:  Show this help"
  echo "This script creates $MSMTPRC with the content of the following variables:"
  echo "  \$RAILS_SMTP_HOST=$RAILS_SMTP_HOST"
  echo "  \$RAILS_SMTP_PORT=$RAILS_SMTP_PORT"
  echo "  \$RAILS_SMTP_USER=$RAILS_SMTP_USER"
  echo "  \$RAILS_SMTP_PASS=$RAILS_SMTP_PASS"
  echo "  \$RAILS_SMTP_FROM=$RAILS_SMTP_FROM"
}
while [[ $1 != "" ]]; do
  case $1 in
    -h | --help )
      show_help
      exit
      ;;
    -f | --force )
      FORCE=1
      ;;
  esac
  shift
done

if [[ $RAILS_SMTP_HOST == "" ]]; then
  echo "FATAL: environment variable \$RAILS_SMTP_HOST is empty!"
  exit
elif [[ -a $MSMTPRC && $FORCE != "1" ]]; then
  echo "FATAL: $MSMTPRC exists; use -f or --force to overwrite"
  exit
else
  [[ -a $MSMTPRC ]] && echo "WARNING: $MSMTPRC exists; forcing overwrite!"
  # Note that the heredoc lines must be preceded by true tabs
  cat <<-EOF | tee $MSMTPRC
		# msmtp configuration written by dora ($(basename $0)) on $(date -Is)
		account default
		host $RAILS_SMTP_HOST
		port $RAILS_SMTP_PORT
		user $RAILS_SMTP_USER
		from $RAILS_SMTP_FROM
		password $RAILS_SMTP_PASS
		tls_starttls
		EOF
  chown root:root $MSMTPRC
  chmod 0600 $MSMTPRC
fi
