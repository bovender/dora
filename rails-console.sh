#!/bin/bash
set -x
cd /home/app/rails
bin/rails -e $PASSENGER_APP_ENV
