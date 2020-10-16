#!/usr/bin/env bash

# dora-status.sh
# This script is part of dora -- Docker container for Rails
# https://github.com/bovender/dora

APP_DIR=/home/dora/rails
LOG_TAIL_LINES=12

if [[ $GIT_PULL == "true" ]]; then
  GIT_DESCRIPTION=`git -C $APP_DIR describe 2>/dev/null`
else
  GIT_DESCRIPTION="(not a Git repository)"
fi

echo -e "# dora status\n"
echo "- Application mame:   $APP_NAME"
echo "- Repository version: $GIT_DESCRIPTION"

echo -e "\n\n## top"
top -b -n 1 | tail -n +7 | head -n 6

echo -e "\n\n## nginx status\n"
# TODO: need to e sudo?
sv status nginx

echo -e "\n\n## sidekiq status\n"
sv status sidekiq

echo -e "\n\n## Passenger status\n"
passenger-status

echo -e "\n\n## Log tails"
for F in $APP_DIR/log/*.log; do
  echo -e "\n### ${F##*/}"
  echo "\`\`\`"
  tail -n $LOG_TAIL_LINES $F
  echo "\`\`\`"
done

echo -e "\n---"
