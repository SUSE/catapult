#!/bin/bash

. ../../include/common.sh

TMPDIR="${TMPDIR:-/tmp}" # required to be able to mount configs in deployments containers (dind mount )

info "Building wtty image"
pushd "$ROOT_DIR"/kube/catapult-wtty
    docker build -t catapult-wtty .
popd

info "Building sync image"
pushd "$ROOT_DIR"/kube/catapult-sync
    docker build --build-arg=EKCP_HOST=$EKCP_HOST -t catapult-sync .
popd

info "Building redirector image"
pushd "$ROOT_DIR"/kube/catapult-web
    docker build -t catapult-web .
popd

docker rm --force catapult-sync || true
docker rm --force catapult-web || true

docker rm --force $(docker ps -f name=catapult-wtty --format={{.Names}}) || true

docker run -d --restart=always -v /var/run/docker.sock:/var/run/docker.sock --name catapult-sync catapult-sync
docker run -e TMPDIR=$TMPDIR -v $TMPDIR:$TMPDIR -e EKCP_HOST="$EKCP_HOST" -d -p 7060:8080 --restart=always -v /var/run/docker.sock:/var/run/docker.sock --name catapult-web catapult-web

ok "Now you can head with your browser to http://127.0.0.1:7060!"
