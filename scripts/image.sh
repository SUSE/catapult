#!/bin/bash

. ../include/versioning

TAG=${TAG:-$ARTIFACT_VERSION}
DOCKER_IMAGE=${DOCKER_IMAGE:-${DOCKER_ORG}catapult:${TAG}}

docker build --rm --no-cache -t ${DOCKER_IMAGE} .
