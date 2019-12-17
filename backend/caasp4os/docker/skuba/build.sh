#!/usr/bin/env bash

REPO_ENV="$1"
REPO="$2"
VERSION=

retrieve_version() {
  local output=$(docker run --rm -ti registry.suse.com/suse/sle15 sh -c "zypper rr -a && zypper ar -G http://download.suse.de/ibs/SUSE/Products/SUSE-CAASP/4.0/x86_64/product/ caasp4-product && zypper ar -G $REPO skuba-$REPO_ENV > /dev/null 2>&1 && zypper --no-color --no-gpg-checks info -r skuba-$REPO_ENV skuba")

  if [[ $? -eq 0 ]]; then
    # 0.5.0-1.2 ^M$
    VERSION="$(echo -n "$output" | grep --color=never "Version" | sed 's/V.*: //' | tr -d ' \t\n\r')"

    echo ">>> INFO: skuba version found, $VERSION"
    return
  fi

  if [[ -z $VERSION ]]; then
    echo ">>> ERROR: no skuba version found" && exit 1
  fi
}

build_container() {
  # local IMAGE_NAME="skuba/$REPO_ENV-$VERSION"
  local IMAGE_NAME="skuba/$REPO_ENV"

  if [[ "$(docker images -q skuba/$CAASP_VER 2> /dev/null)" == "" ]]; then
      echo ">>> INFO: Building $IMAGE_NAME"
      docker build --no-cache -t "$IMAGE_NAME" \
             --build-arg VERSION="$VERSION" \
             --build-arg REPO_ENV="$REPO_ENV" \
             --build-arg REPO="$REPO" .
  fi
}

retrieve_version
build_container
