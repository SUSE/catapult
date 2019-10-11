#!/bin/bash
set -ex

. ../../include/common.sh

docker stop $CLUSTER_NAME-control-plane
