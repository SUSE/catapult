#!/bin/bash
set -x

pushd build
    ./kind create cluster
popd