#!/bin/bash
# Theses variables HEAT_* are replaces by heat str_replace
ALL_MANAGE_IP="HEAT_ALL_MANAGE_IP"
ALL_STORAGE_IP="HEAT_ALL_STORAGE_IP"
ALL_BRICK_DEVICE="HEAT_ALL_BRICK_DEVICE"

TEMPLATE=/usr/heat_heketi_topology.json

i=1
for manage_ip in $ALL_MANAGE_IP; do
  sed -ie "s/NODE_${i}_MANAGE_IP/$manage_ip/g" $TEMPLATE
  i=$(( $i + 1 ))
done

i=1
for storage_ip in $ALL_STORAGE_IP; do
  sed -ie "s/NODE_${i}_STORAGE_IP/$storage_ip/g" $TEMPLATE
  i=$(( $i + 1 ))
done

i=1
for device in $ALL_BRICK_DEVICE; do
  # For virtio scsi
  sed -ie "s/NODE_${i}_DEVICE/\/dev\/disk\/by-id\/scsi-0QEMU_QEMU_HARDDISK_${device:0:20}/g" $TEMPLATE
  i=$(( $i + 1 ))
done
