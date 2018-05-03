#!/bin/bash
sudo groupmod -g $(stat -c '%g' /var/run/docker.sock) docker
sudo usermod -a -G docker jenkins
exec su jenkins -c "/usr/local/bin/start.sh $*"
