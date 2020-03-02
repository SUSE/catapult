#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

supported_backend "kind"

if [ ! -e "bin/fissile" ]; then
    # Takes a dev bosh release checkout and make it an image. Upload it also to the kind cluster
    info "Building fissile from develop"
    mkdir -p buildfissile
    pushd buildfissile || exit
    mkdir -p src                                  # make the directory src in your workspace
    export GOPATH=$PWD                            # set GOPATH to current working directory
    go get -d code.cloudfoundry.org/fissile || true      # Download sources
    pushd $GOPATH/src/code.cloudfoundry.org/fissile || exit
    make tools                              # install required tools; only needed first time
    make docker-deps                        # pull docker images required to build
    make build
    popd || exit
    popd || exit
    mv $GOPATH/src/code.cloudfoundry.org/fissile/build/linux-amd64/fissile bin/
    rm -rf buildfissile
fi

info "Building bosh release"
# Keep fissile generated cache inside our build dir
export HOME=$PWD
pushd ${FISSILE_OPT_BOSH_RELEASE} || exit

GIT_COMMIT=$(git rev-parse --short HEAD)
BOSH_REL="${FISSILE_OPT_RELEASE_NAME}"-dev-"${GIT_COMMIT}".tgz

docker run --rm -ti -v ${FISSILE_OPT_BOSH_RELEASE}:/bosh-release \
            splatform/bosh-cli \
            /bin/bash -c "cd /bosh-release && bosh reset-release"

docker run --rm -ti -v ${FISSILE_OPT_BOSH_RELEASE}:/bosh-release \
            splatform/bosh-cli \
            /bin/bash -c "cd /bosh-release && bosh create-release --force --tarball=${BOSH_REL} --name=${FISSILE_OPT_RELEASE_NAME} --version=${FISSILE_OPT_RELEASE_VERSION} && chmod 777 ${BOSH_REL}"

#git submodule sync --recursive && git submodule update --init --recursive && git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
popd || exit

mv ${FISSILE_OPT_BOSH_RELEASE}/"${BOSH_REL}" ./
SHA=$(sha1sum ${PWD}/${BOSH_REL} | cut -d' ' -f1)

info "Fissilizing it!"
docker pull "${FISSILE_OPT_STEMCELL}"

out=$(fissile build release-images --stemcell="${FISSILE_OPT_STEMCELL}" \
                                 --url "file://${PWD}/${BOSH_REL}" \
                                 --name=${FISSILE_OPT_RELEASE_NAME} \
                                 --docker-registry=${FISSILE_OPT_DOCKER_REGISTRY} \
                                 --docker-organization=${FISSILE_OPT_DOCKER_ORG} \
                                 --sha1="${SHA}" \
                                 -w="$PWD" \
                                 --version="${FISSILE_OPT_RELEASE_VERSION}")
# Load image to cluster
name=$(echo $out | awk 'NR==1 {print; exit}' | grep -oh "${FISSILE_OPT_RELEASE_NAME}:.*$")

ok "Image available as $name"

kind load docker-image --name=${CLUSTER_NAME} $name


info "You might want to regenerate the scf-configs with an override to use this build, and upgrade/redeploy scf, e.g:"
info
cat <<EOFOUT
CONFIG_OVERRIDE=\$(cat <<EOF
releases:
  eirini:
    version: $FISSILE_OPT_RELEASE_VERSION
    stemcell:
      os: SLE_15_SP1
      version: 15.1-7.0.0_374.gb8e8e6af
EOF
)
EOFOUT

info 'make scf-build'
