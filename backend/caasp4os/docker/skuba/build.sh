#!/usr/bin/env bash

REPO_ENV="$1"
REPO="$2"
IMAGE_NAME="skuba/$REPO_ENV"

if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
  echo ">>> INFO: Building $IMAGE_NAME"
  docker build --no-cache -t "$IMAGE_NAME" \
         --build-arg VERSION="$(date -I)" \
         --build-arg REPO_ENV="$REPO_ENV" \
         --build-arg REPO="$REPO" .
fi
