#!/bin/bash
set -x

. ../../include/common.sh
. .envrc

set -Eexo pipefail

curl -d "name=${CLUSTER_NAME}" -X POST http://$EKCP_HOST/new