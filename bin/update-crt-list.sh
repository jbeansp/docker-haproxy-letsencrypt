#!/bin/sh
set -e
set -x
changed=no
list=
txt=/etc/letsencrypt/crt-list.txt
echo Updating $txt

touch $txt
mkdir -p /etc/letsencrypt/live
cd /etc/letsencrypt/live
for domain in "$(ls -d */ 2>/dev/null)"; do
    if [ "$domain" = "README" ]; then continue; fi
    cd "$domain"
    if [ -f fullchain.pem -a -f privkey.pem ]; then
        # Check if something has changed
        old=
        [ -f combined.pem ] && old="$(cat combined.pem)"
        current="$(cat fullchain.pem privkey.pem)"
        if [ "$old" != "$current" ]; then
            # Store new combined cert
            echo "$current" > combined.pem
            changed=yes
        fi
        list="$list$(pwd)/combined.pem\n"
    fi
    cd ..
done

# Check if domains list or any cert has changed
if [ "$list" != "$(cat $txt)" -o $changed == yes ]; then
    # Update list and reload server
    echo -e "$list" > $txt
    reload.sh
else
    printf "No changes detected. In case of error, here's /var/log/letsencrypt/letsencrypt.log\n"
    cat /var/log/letsencrypt/letsencrypt.log
fi
