#!/bin/bash

. scripts/include/versioning

TAG=${TAG:-$ARTIFACT_VERSION}
DOCKER_IMAGE=${DOCKER_IMAGE:-${DOCKER_ORG}bkindwscf:${TAG}}

docker build --rm --no-cache -t ${DOCKER_IMAGE} .
