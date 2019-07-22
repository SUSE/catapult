#!/bin/bash
set -ex 

. scripts/include/common.sh

cf login --skip-ssl-validation -a https://api.${container_ip}.nip.io -u admin -p password -o system
cf create-space tmp
cf target -s tmp