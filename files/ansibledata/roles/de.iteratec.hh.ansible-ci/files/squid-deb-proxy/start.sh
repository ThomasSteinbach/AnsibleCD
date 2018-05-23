#!/bin/bash

if [[ "$1" == 'get-cacert' ]]; then
  cat /etc/squid/ssl_cert/myCA.pem
  exit 0
fi

# Necessary because squid forks itself to an unprivileged process.
chown proxy:proxy /dev/stdout

exec /usr/sbin/squid -N -d1
