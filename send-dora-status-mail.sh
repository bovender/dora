#!/usr/bin/env bash

# send-dora-status-mail.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

TMP_FILE="/tmp/dora_mail_$(date -Ins).mbox"

echo "# dora sending status mail"

if [[ $RAILS_SMTP_FROM == "" ]]; then
  echo "FATAL: Cannot send status mail because \$RAILS_SMTP_FROM is empty."
  exit 1
elif [[ $EMAIL_REPORTS_TO == "" ]]; then
  echo "FATAL: Cannot send status mail because \$EMAIL_REPORTS_TO is empty."
  exit 2
else
  # Note that the heredoc lines must be preceded by tabs, not spaces!
	cat <<-EOF | msmtp $EMAIL_REPORTS_TO
		To: $EMAIL_REPORTS_TO
		Subject: [$APP_NAME] dora status report

		$(dora-status.sh)
		EOF
fi
