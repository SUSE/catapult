#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

supported_backend "kind"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -e "bin/fissile" ]; then
    # Takes a dev bosh release checkout and make it an image. Upload it also to the kind cluster
    info "Building fissile from develop"
    mkdir -p buildfissile
    pushd buildfissile
    mkdir -p src                                  # make the directory src in your workspace
    export GOPATH=$PWD                            # set GOPATH to current working directory
    go get -d code.cloudfoundry.org/fissile || true      # Download sources
    pushd $GOPATH/src/code.cloudfoundry.org/fissile
    make tools                              # install required tools; only needed first time
    make docker-deps                        # pull docker images required to build
    make build
    popd
    popd
    mv $GOPATH/src/code.cloudfoundry.org/fissile/build/linux-amd64/fissile bin/
    rm -rf buildfissile
fi

info "Building bosh release"
# Keep fissile generated cache inside our build dir
export HOME=$PWD
pushd ${FISSILE_OPT_BOSH_RELEASE}

GIT_COMMIT=$(git rev-parse --short HEAD)
BOSH_REL="${FISSILE_OPT_RELEASE_NAME}"-dev-"${GIT_COMMIT}".tgz

docker run --rm -ti -v ${FISSILE_OPT_BOSH_RELEASE}:/bosh-release \
            splatform/bosh-cli \
            /bin/bash -c "cd /bosh-release && bosh reset-release"

docker run --rm -ti -v ${FISSILE_OPT_BOSH_RELEASE}:/bosh-release \
            splatform/bosh-cli \
            /bin/bash -c "cd /bosh-release && bosh create-release --force --tarball=${BOSH_REL} --name=${FISSILE_OPT_RELEASE_NAME} --version=${FISSILE_OPT_RELEASE_VERSION} && chmod 777 ${BOSH_REL}"

#git submodule sync --recursive && git submodule update --init --recursive && git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
popd

mv ${FISSILE_OPT_BOSH_RELEASE}/"${BOSH_REL}" ./
SHA=$(sha1sum ${PWD}/${BOSH_REL} | cut -d' ' -f1)

info "Fissilizing it!"
docker pull "${FISSILE_OPT_STEMCELL}"

out=$(fissile build release-images --stemcell="${FISSILE_OPT_STEMCELL}" \
                                 --url "file://${PWD}/${BOSH_REL}" \
                                 --name=${FISSILE_OPT_RELEASE_NAME} \
                                 --sha1="${SHA}" \
                                 -w="$PWD" \
                                 --version="${FISSILE_OPT_RELEASE_VERSION}")
# Load image to cluster
name=$(echo $out | awk 'NR==1 {print; exit}' | grep -oh "${FISSILE_OPT_RELEASE_NAME}:.*$")

ok "Image available as $name"

kind load docker-image --name=${CLUSTER_NAME} $name