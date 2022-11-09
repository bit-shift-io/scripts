#!/bin/bash

hostname=$(hostname)
archive=$HOME/docker-${hostname}.tar.gz
backup=$HOME/Docker
containers=$(docker container list -qa)

echo "stop containers"
sudo docker container stop ${containers}

echo "create backup..."
echo ${archive}
sudo tar -czvf ${archive} ${backup} > /dev/null

echo "restart containers"
sudo docker restart ${containers}

echo "done!"