#!/bin/bash
set -x

# duplicated in s/include/common.sh, needed for bootstrapping:
. include/common.sh

mkdir "$BUILD_DIR"
. include/common.sh # Reload, as we just created BUILD_DIR

mkdir bin

cat <<HEREDOC > .envrc
export CLUSTER_NAME=${CLUSTER_NAME}
export BACKEND=${BACKEND}
HEREDOC

cat <<'HEREDOC_LITERAL_APPEND' >> .envrc
export KUBECONFIG="$(pwd)"/kubeconfig
export HELM_HOME="$(pwd)"/.helm
export CF_HOME="$(pwd)"
export PATH="$PATH:$(pwd)"/bin
export MINIKUBE_HOME="$(pwd)"/.minikube
HEREDOC_LITERAL_APPEND

popd
