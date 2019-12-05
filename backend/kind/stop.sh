#!/bin/bash

. ../../include/common.sh

docker stop $CLUSTER_NAME-control-plane
