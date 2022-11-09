#!/bin/bash

hostname=$(hostname)
archive=$HOME/docker-${hostname}.tar.gz
backup=$HOME/Docker

containers=$(docker container list -qa)
sudo docker container stop ${containers}

sudo tar -c -f -z -v  ${archive} ${backup}

sudo docker restart ${containers}