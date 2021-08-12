#!/bin/sh

# this is called by cron. see /etc/periodic/monthly
# $RENEW command is set in the Dockerfile
set -e
echo Asking for certificate renewal
$RENEW
