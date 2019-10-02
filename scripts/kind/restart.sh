#!/bin/bash

set -ex

. ../include/common.sh

docker exec -ti $CLUSTER_NAME-control-plane \
    /bin/bash -c 'docker restart $(docker ps -q)'
