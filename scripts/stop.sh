#!/bin/bash
set -x

pushd build
    cluster_name=$(./kind get clusters)
    docker stop $cluster_name-control-plane
popd