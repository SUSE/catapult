#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

curl -d "name=${CLUSTER_NAME}" -X POST http://$EKCP_HOST/new
