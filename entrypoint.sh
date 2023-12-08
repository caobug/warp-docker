#!/bin/bash

# exit when any command fails
set -e

# create a tun device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# start the daemon
warp-svc &

# if /var/lib/cloudflare-warp/reg.json not exists, register the warp client
if [ ! -f /var/lib/cloudflare-warp/reg.json ]; then
    # sleep to wait for the daemon to start, default 2 seconds
    sleep "$WARP_SLEEP"
    if [ -n "$WARP_ORGANIZATION" ]; then
        {
            echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
            echo "<dict>"
            echo "    <key>organization</key>"
            echo "    <string>$WARP_ORGANIZATION</string>"
            echo "    <key>auth_client_id</key>"
            echo "    <string>$WARP_AUTH_CLIENT_ID</string>"
            echo "    <key>auth_client_secret</key>"
            echo "    <string>$WARP_AUTH_CLIENT_SECRET</string>"
            echo "</dict>"
        }>/var/lib/cloudflare-warp/mdm.xml
    else
        warp-cli register && echo "Warp client registered!"
        # if a license key is provided, register the license
        if [ -n "$WARP_LICENSE_KEY" ]; then
            echo "License key found, registering license..."
            warp-cli set-license "$WARP_LICENSE_KEY" && echo "Warp license registered!"
        fi
    fi
    # connect to the warp server
    warp-cli connect
else
    echo "Warp client already registered, skip registration"
fi

# start the proxy
gost $GOST_ARGS
