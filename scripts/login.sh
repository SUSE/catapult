#!/bin/bash
set -ex 
pushd build

cluster_name=$(./kind get clusters)
container_id=$(docker ps -f "name=${cluster_name}-control-plane" -q)
container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)

cf login --skip-ssl-validation -a https://api.${container_ip}.nip.io -u admin -p password -o system
cf create-space tmp
cf target -s tmp