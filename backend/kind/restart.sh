#!/bin/bash

set -e

. ../../include/common.sh

debug_mode

docker exec -ti $CLUSTER_NAME-control-plane \
    /bin/bash -c 'docker restart $(docker ps -q)'
