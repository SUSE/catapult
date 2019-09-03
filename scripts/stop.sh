#!/bin/bash
set -ex

. scripts/include/common.sh

docker stop $CLUSTER_NAME-control-plane
