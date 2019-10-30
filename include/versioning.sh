#!/bin/sh

GIT_ROOT=${GIT_ROOT:-$(git rev-parse --show-toplevel)}
GIT_DESCRIBE=${GIT_DESCRIBE:-$(git describe --tags --long)}
GIT_BRANCH=${GIT_BRANCH:-$(git name-rev --name-only HEAD)}
if [ -n "$GIT_DESCRIBE" ]; then

GIT_TAG=${GIT_TAG:-$(echo ${GIT_DESCRIBE} | gawk -F - '{ print $1 }' )}
GIT_COMMITS=${GIT_COMMITS:-$(echo ${GIT_DESCRIBE} | gawk -F - '{ print $2 }' )}
GIT_SHA=${GIT_SHA:-$(echo ${GIT_DESCRIBE} | gawk -F - '{ print $3 }' )}

ARTIFACT_NAME=${ARTIFACT_NAME:-$(basename $(git config --get remote.origin.url) .git | sed s/^scf-//)}
ARTIFACT_VERSION=${GIT_TAG}.${GIT_COMMITS}.${GIT_SHA}
else
ARTIFACT_VERSION=latest
fi
