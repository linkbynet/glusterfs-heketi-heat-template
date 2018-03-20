#!/bin/bash

set -e
set -x

# Documentation : https://wiki.centos.org/HowTos/GlusterFSonCentOS

# Glusterfs installation
yum install -y centos-release-gluster39 
yum install -y glusterfs gluster-cli glusterfs-libs glusterfs-server
systemctl enable glusterd.service
systemctl start glusterd.service

