#!/bin/bash
set -ex
# https://github.com/kubernetes-sigs/kind/issues/148#issuecomment-504708204

. ../../include/common.sh

docker start $CLUSTER_NAME-control-plane
docker exec $CLUSTER_NAME-control-plane sh -c 'mount -o remount,ro /sys; kill -USR1 1'
