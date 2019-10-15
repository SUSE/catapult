#!/bin/bash
set -e

. ../../include/common.sh

debug_mode

docker stop $CLUSTER_NAME-control-plane
