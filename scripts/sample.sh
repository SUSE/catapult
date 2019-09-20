#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

SAMPLE_APP_REPO="${SAMPLE_APP_REPO:-https://github.com/cloudfoundry-samples/cf-sample-app-nodejs}"

[ ! -d "sample" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" sample

pushd sample

cf push