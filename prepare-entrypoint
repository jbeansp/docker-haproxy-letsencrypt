#!/bin/sh
set -e
if [ "$STAGING" == true ]; then
    export STAGING_FLAG="staging = true"
fi
expand-certbot-ini
certonly
update-crt-list
echo Activating cron daemon
crond
echo Executing: $@
# docker-entrypoint.sh comes from the haproxy base image
# it's been at root dir, and also in /usr/local/bin
export PATH="${PATH}:/:/usr/local/bin"
exec docker-entrypoint.sh "$@"