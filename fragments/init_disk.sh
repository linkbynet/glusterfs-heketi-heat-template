#!/bin/bash

set -e
set -x

function configure_disk() {
  devlink=$1
  mkfs.xfs -i size=512 $devlink
  mkdir -p /data/brick
  echo "$devlink /data/brick xfs defaults 1 2" >> /etc/fstab
  mount -a && mount
}

function init_disk() {
  for devlink in /dev/disk/by-id/virtio-${1:0:20} /dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_${1:0:20}; do
    # Follow link if is link
    if [ -e $devlink ]; then
      if [ -L $devlink ]; then
        devlink=$(readlink -f $devlink)
      fi
      configure_disk $devlink
      return 0
    fi
  done
  echo "Disk $1 not found" 1>&2
  return 1
}  


# Heat str_replace
init_disk $BRICK_VOLUME_ID

