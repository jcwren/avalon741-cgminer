#!/bin/bash

#
# If git keeps asking for credentials, run this command
#   git config --global credential.helper store
#

if [ ! -f config ]; then
  echo "IMG_NAME='Raspian'" >config
  echo "APT_PROXY=http://172.17.0.1:3142" >>config
fi

if [ ! -d apt-cacher-ng ]; then
  docker-compose up -d
fi

docker rm -vf pigen_work >/dev/null 2>&1
docker image rm -f pi-gen >/dev/null 2>&1
docker image prune -f >/dev/null 2>&1

rm -rf deploy/*

rm -f stage*/SKIP
rm -f stage*/EXPORT_NOOBS
rm -rf stage4 stage5

./build-docker.sh

if [ -f deploy/*.bzip2 ]; then
  IMAGE=`find deploy -name \*.bzip2 | sort | tail -n 1`
  mv ${IMAGE} deploy/cgminer_image.img.bz2
fi
