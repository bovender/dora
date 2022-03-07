#!/usr/bin/env bash

# Prints an informative banner.

echo
echo "         _/                             "
echo "    _/_/_/    _/_/    _/  _/_/    _/_/_/"
echo " _/    _/  _/    _/  _/_/      _/    _/ "
echo "_/    _/  _/    _/  _/        _/    _/  "
echo " _/_/_/    _/_/    _/          _/_/_/   "
echo
echo "==== Docker environment for Rails ====="
echo "======================================="
echo
echo "= APP_NAME:                  $APP_NAME"
echo "= USER:                      $USER"
echo "= GID:                       $UID"
echo "= UID:                       $GID"
echo "= PASSENGER_APP_ENV:         $PASSENGER_APP_ENV"
echo "= DORA_HOST_APP_DIR:         $DORA_HOST_APP_DIR"
echo "= DORA_HOST_VOL_DIR:         $DORA_HOST_VOL_DIR"
echo "= GIT_PULL:                  $GIT_PULL"
echo "= GIT_USER:                  $GIT_USER"
echo "= GIT_PASS:                  $GIT_PASS"
echo "= GIT_REPO:                  $GIT_REPO"
echo "= GIT_BRANCH:                $GIT_BRANCH"
echo "= RAILS_PRECOMPILE_ASSETS:   $RAILS_PRECOMPILE_ASSETS"
echo "= RAILS_DB_HOST:             $RAILS_DB_HOST"
echo "= RAILS_DB_NAME:             $RAILS_DB_NAME"
echo "= RAILS_DB_USER:             $RAILS_DB_USER"
echo "= RAILS_DB_PASS:             $RAILS_DB_PASS"
echo "= RAILS_SMTP_HOST:           $RAILS_SMTP_HOST"
echo "= RAILS_SMTP_PORT:           $RAILS_SMTP_PORT"
echo "= RAILS_SMTP_USER:           $RAILS_SMTP_USER"
echo "= RAILS_SMTP_PASS:           $RAILS_SMTP_PASS"
echo "= RAILS_SMTP_FROM:           $RAILS_SMTP_FROM"
echo "= EMAIL_REPORTS_TO:          $EMAIL_REPORTS_TO"
echo "= TIMEZONE:                  $TIMEZONE"
echo "= NO_WKHTMLTOPDF:            $NO_WKHTMLTOPDF"
echo "= \`which wkhtmltopdf\`:       $(which wkhtmltopdf)"
echo "= PATH:                      $PATH"
echo
echo "======================================="
echo "=== https://github.com/bovender/dora =="
echo "======================================="
echo
