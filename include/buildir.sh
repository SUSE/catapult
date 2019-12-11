#!/bin/bash

# duplicated in s/include/common.sh, needed for bootstrapping:
. $ROOT_DIR/include/common.sh
set +Eeuo pipefail # unset options as we will call include/common.sh again

info "Creating $BUILD_DIR"

if [ ! -d "$BUILD_DIR" ]; then
    mkdir "$BUILD_DIR"
fi

. $ROOT_DIR/include/common.sh # Reload, as we just created BUILD_DIR

if [ ! -d "bin" ]; then
    mkdir bin
fi

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

info "Generating default options file"
rm -rf defaults.sh
echo '#!/usr/bin/env bash' >> defaults.sh
echo '# DISCLAIMER!' >> defaults.sh
echo '# DEFAULT VALUES. DO NOT CHANGE THIS FILE' >> defaults.sh
sed '1d' "$ROOT_DIR"/include/defaults_global.sh >> defaults.sh
set +x
sed '1d' "$ROOT_DIR"/include/defaults_global_private.sh >> defaults.sh
debug_mode

for d in "$ROOT_DIR"/backend/*/ ; do
    if [ -f "$d"/defaults.sh ]; then
        sed '1d' "$d"/defaults.sh >> defaults.sh
    fi
done
for d in "$ROOT_DIR"/modules/*/ ; do
    if [ -f "$d"/defaults.sh ]; then
        sed '1d' "$d"/defaults.sh >> defaults.sh
    fi
done

popd
