#!/bin/sh

if [[ $OSTYPE != darwin* ]]; then
  echo "*"
  echo "* Sorry, this script is written for OS X, not ${OSTYPE}"
  echo "*"
  exit
fi

DISK=
BZIP2IMG=`ls -1 deploy/*.img.bz2 | sort | tail -n 1`

if [ "${BZIP2IMG}" == "" ]; then
  echo "*"
  echo "*  No swarm_image_<version>.img.bz2 file exists. Aborting..."
  echo "*"
  exit
fi

for i in /dev/rdisk[0-9]; do
  diskutil info ${i} | egrep -q "Device / Media Name:.*SD Card Reader"; RES=$?
  if [ "${RES}" == "0" ]; then
    DISK=${i}
  fi
done

if [ "${DISK}" == "" ]; then
  echo "*"
  echo "*  SD card / SD card reader not found!"
  echo "*"
  exit
fi

echo "Copying ${BZIP2IMG} to ${DISK}. sudo password will be needed for 'dd'"

diskutil unmountdisk ${DISK}
sudo sh -c "bzip2 --stdout --decompress --keep ${BZIP2IMG} | dd of=${DISK} bs=16m"
diskutil eject ${DISK}
