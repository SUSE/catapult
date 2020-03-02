#!/bin/bash

. ./defaults.sh
. ../../include/common.sh

info "Building wtty image"
pushd "$ROOT_DIR"/kube/catapult-wtty || exit
    docker build -t catapult-wtty .
popd || exit

info "Building sync image"
pushd "$ROOT_DIR"/kube/catapult-sync || exit
    docker build --build-arg=EKCP_HOST=$EKCP_HOST -t catapult-sync .
popd || exit

info "Building redirector image"
pushd "$ROOT_DIR"/kube/catapult-web || exit
    docker build -t catapult-web .
popd || exit

docker rm --force catapult-sync || true
docker rm --force catapult-web || true

docker rm --force $(docker ps -f name=catapult-wtty --format={{.Names}}) || true

docker run -d --restart=always -v /var/run/docker.sock:/var/run/docker.sock --name catapult-sync catapult-sync
docker run -e TMPDIR=$TMPDIR -v $TMPDIR:$TMPDIR -e EKCP_HOST="$EKCP_HOST" -d -p 7060:8080 --restart=always -v /var/run/docker.sock:/var/run/docker.sock --name catapult-web catapult-web

ok "Now you can head with your browser to http://127.0.0.1:7060!"
