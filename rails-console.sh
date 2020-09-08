#!/bin/bash
set -x
cd /home/app/app
bin/rails -e $PASSENGER_APP_ENV
