#!/bin/bash
set -ex

. scripts/include/common.sh

docker stop $cluster_name-control-plane