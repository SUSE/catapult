#!/bin/bash
set -ex
# https://github.com/kubernetes-sigs/kind/issues/148#issuecomment-504708204

. scripts/include/common.sh

docker start $cluster_name-control-plane
docker exec $cluster_name-control-plane sh -c 'mount -o remount,ro /sys; kill -USR1 1'
