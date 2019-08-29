#!/bin/bash
set -ex 

. scripts/include/common.sh

if [ -n "$EKCP_PROXY" ]; then
  export https_proxy=socks5://127.0.0.1:2224
fi

cf login --skip-ssl-validation -a https://api.${DOMAIN} -u admin -p ${CLUSTER_PASSWORD} -o system
cf create-space tmp
cf target -s tmp