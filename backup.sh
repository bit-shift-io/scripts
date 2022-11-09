#!/bin/bash

hostname=$(hostname)
archive=$HOME/docker-${hostname}.tar.gz
backup=$HOME/Docker
containers=$(docker container list -qa)

echo "stop containers"
sudo docker container stop ${containers}

echo "create backup..."
sudo tar -c -f -z -v  ${archive} ${backup} > /dev/null

echo "restart containers"
sudo docker restart ${containers}