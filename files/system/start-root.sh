#!/bin/bash
if [ -S /var/run/docker.sock ]; then
  groupmod -g $(stat -c '%g' /var/run/docker.sock) docker
  usermod -a -G docker jenkins
fi
exec su jenkins -c "/usr/local/bin/start.sh $*"
