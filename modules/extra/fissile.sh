#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ -e "bin/fissile" ]; then
    # Takes a dev bosh release checkout and make it an image. Upload it also to the kind cluster
    info "Building fissile from develop"
    mkdir -p buildfissile
    pushd buildfissile
    mkdir -p src                                  # make the directory src in your workspace
    export GOPATH=$PWD                            # set GOPATH to current working directory
    go get -d code.cloudfoundry.org/fissile       # Download sources
    pushd $GOPATH/src/code.cloudfoundry.org/fissile
    make tools                              # install required tools; only needed first time
    make docker-deps                        # pull docker images required to build
    make build
    popd
    popd
    mv buildfissile/$GOPATH/src/code.cloudfoundry.org/fissile/build/linux-amd64/fissile bin/
    rm -rf buildfissile
fi

info "Building bosh release"
# Keep fissile generated cache inside our build dir
export HOME=$PWD
pushd ${FISSILE_BOSH_RELEASE}

GIT_COMMIT=$(git rev-parse --short HEAD)
BOSH_REL="${FISSILE_RELEASE_NAME}"-dev-"${GIT_COMMIT}".tgz

#git submodule sync --recursive && git submodule update --init --recursive && git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
bosh create-release --force --tarball="${BOSH_REL}"
popd

mv ${FISSILE_BOSH_RELEASE}/"${BOSH_REL}" ./
SHA=$(sha1sum ${PWD}/${BOSH_REL} | cut -d' ' -f1)

info "Fissilizing it!"
bin/fissile build release-images --stemcell="${FISSILE_STEMCELL}" \
                                 --url "file://${PWD}/${BOSH_REL}" \
                                 --name "${FISSILE_RELEASE_NAME}" \
                                 --sha1="${SHA}" \
                                 -w="$PWD" \
                                 --version="${FISSILE_RELEASE_VERSION}"
# Load image to cluster