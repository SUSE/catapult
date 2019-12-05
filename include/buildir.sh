#!/bin/bash

# duplicated in s/include/common.sh, needed for bootstrapping:
. $ROOT_DIR/include/common.sh
set +Eeuo pipefail # unset options as we will call include/common.sh again

info "Creating $BUILD_DIR"
mkdir "$BUILD_DIR"
. $ROOT_DIR/include/common.sh # Reload, as we just created BUILD_DIR

mkdir bin

info "Generating .envrc"
cat <<HEREDOC > .envrc
export CLUSTER_NAME=${CLUSTER_NAME}
export BACKEND=${BACKEND}
HEREDOC

cat <<HEREDOC_APPEND >> .envrc
export KUBECONFIG="$(pwd)"/kubeconfig
export HELM_HOME="$(pwd)"/.helm
export CF_HOME="$(pwd)"
export PATH="$(pwd)"/bin:"$PATH"
export MINIKUBE_HOME="$(pwd)"/.minikube
HEREDOC_APPEND

popd
