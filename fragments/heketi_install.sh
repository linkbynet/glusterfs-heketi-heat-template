#!/bin/bash

set -e
set -x

# Documentation : https://github.com/heketi/heketi/blob/master/docs/admin/server.md

# Heketi installation
#yum install -y heketi # does not exist
#systemctl enable heketi.service
#systemctl start heketi.service

mkdir -p heketi/config
mkdir -p heketi/db
cp /usr/heat_heketi_topology.json heketi/config/topology.json
cp /usr/heat_heketi_config.json heketi/config/heketi.json
cp /root/.ssh/id_rsa.pub heketi/config/myprivate_key
chmod 600 heketi/config/myprivate_key
chown 1000:1000 -R heketi

docker run -d -p 8080:8080 \
  -v $PWD/heketi/config:/etc/heketi:Z \
  -v $PWD/heketi/db:/var/lib/heketi:Z \
  --name heketi \
  --restart=always \
  heketi/heketi:latest

# wait and check if it's running
sleep 10
docker inspect -f '{{ .State.Running }}' heketi |grep true
docker inspect -f '{{ .State.Restarting }}' heketi |grep false

curl http://127.0.0.1:8080/hello |grep 'Hello from Heketi'

# Load topology :
docker exec -i heketi heketi-cli topology load --json=/etc/heketi/topology.json

# check peer probe = 2 (replica count - 1)
test $(docker logs heketi 2>/dev/null |grep 'Result: peer probe: success' | wc -l) -eq 2
