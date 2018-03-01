#!/bin/sh

if [[ $OSTYPE != darwin* ]]; then
  echo "*"
  echo "* Sorry, this script is written for OS X, not ${OSTYPE}"
  echo "*"
  exit
fi

DISK=
ZIP2IMG=`ls -1 deploy/image_*.zip | sort | tail -n 1`

if [ "${ZIP2IMG}" == "" ]; then
  echo "*"
  echo "*  No image_YYYY-MM-DD-Raspbian-lite.zip file exists. Aborting..."
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

echo "Copying ${ZIP2IMG} to ${DISK}. sudo password will be needed for 'dd'"

diskutil unmountdisk ${DISK}
sudo sh -c "unzip -p ${ZIP2IMG} | dd of=${DISK} bs=16m"
diskutil eject ${DISK}
