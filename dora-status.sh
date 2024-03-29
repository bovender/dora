#!/usr/bin/env bash

# dora-status.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

source /etc/container_environment.sh
LOG_TAIL_LINES=12

if [[ $GIT_PULL == "true" ]]; then
  GIT_DESCRIPTION=`git -C $RAILS_DIR describe 2>/dev/null`
else
  GIT_DESCRIPTION="(not a Git repository)"
fi

echo -e "# dora status\n"
echo "- Application name:        $APP_NAME"
echo "- Repository version:      $GIT_DESCRIPTION"
echo "- Application environment: $PASSENGER_APP_ENV"

echo -e "\n\n## top\n"
top -b -n 1 | tail -n +7 | head -n 6

echo -e "\n\n## nginx status\n"
sudo sv status nginx

echo -e "\n\n## sidekiq status\n"
sudo sv status sidekiq

echo -e "\n\n## Passenger status\n"
passenger-status

echo -e "\n\n## Log tails"
for F in $RAILS_DIR/log/*.log; do
  echo -e "\n### ${F##*/}"
  echo "\`\`\`"
  tail -n $LOG_TAIL_LINES $F
  echo "\`\`\`"
done

echo -e "\n\n## Pending package upgrades\n"
echo -e "(NB: Package list is not automatically updated for this listing.)\n"
apt-get --simulate dist-upgrade

echo -e "\n---"
