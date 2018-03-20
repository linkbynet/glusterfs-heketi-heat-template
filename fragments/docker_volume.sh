#!/bin/bash

set -e
set -x

# Will be replaced by heat str_replace
DOCKER_DEVICE=HEAT_DOCKER_DEVICE

function configure_disk() {
  devlink=$1
      cat << EOF > /etc/sysconfig/docker-storage-setup
DEVS=$devlink
VG=docker-vg
EOF
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

yum install -y docker

# Heat str_replace
init_disk $DOCKER_DEVICE

systemctl enable docker
systemctl start docker

