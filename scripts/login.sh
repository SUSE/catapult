#!/bin/bash
set -ex 

. scripts/include/common.sh

cf login --skip-ssl-validation -a https://api.${container_ip}.nip.io -u admin -p ${CLUSTER_PASSWORD} -o system
cf create-space tmp
cf target -s tmp