#!/bin/bash
set -e

echo "Building wtty image"
pushd "$ROOT_DIR"/kube/catapult-wtty
    docker build -t catapult-wtty .
popd

echo "Building sync image"
pushd "$ROOT_DIR"/kube/catapult-sync
    docker build --build-arg=EKCP_HOST=$EKCP_HOST -t catapult-sync .
popd

echo "Building redirector image"
pushd "$ROOT_DIR"/kube/catapult-web
    docker build -t catapult-web .
popd

docker rm --force catapult-sync || true
docker rm --force catapult-web || true

docker run -d --restart=always -v /var/run/docker.sock:/var/run/docker.sock --name catapult-sync catapult-sync
docker run -d -p 7060:8080 --restart=always -v /var/run/docker.sock:/var/run/docker.sock:ro --name catapult-web catapult-web

echo "Now you can head with your browser to 127.0.0.1:7060/clustername to have a web tty!"
