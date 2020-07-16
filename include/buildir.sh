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

export HELM_HOME="$(pwd)"/.helm # for helm 2
# The following are needed for helm 3:
export XDG_CACHE_HOME="$(pwd)/.cache"
export XDG_CONFIG_HOME="$(pwd)/.config"
export XDG_DATA_HOME="$(pwd)/.local/share"

export CF_HOME="$(pwd)"
export PATH="$(pwd)"/bin:"$PATH"
export MINIKUBE_HOME="$(pwd)"/.minikube
export CLOUDSDK_CONFIG="$(pwd)/.config/gcloud"
export AWS_CONFIG_FILE="$(pwd)/.aws/config"
export AWS_SHARED_CREDENTIALS_FILE="$(pwd)/.aws/credentials"

export GEM_HOME="$(pwd)/.gem_home"
export GEM_PATH="$(pwd)/.gem_home"
HEREDOC_APPEND

info "Generating default options file"
rm -rf defaults.sh
echo '#!/usr/bin/env bash' >> defaults.sh
echo >> defaults.sh
echo '# DISCLAIMER!!!!!!!!' >> defaults.sh
echo '# DISCLAIMER!!!!!!!!      CHANGING THIS FILE HAS NO EFFECT ANYWHERE for now' >> defaults.sh
echo '# DISCLAIMER!!!!!!!!      It is a concat of all possible options,' >> defaults.sh
echo '# DISCLAIMER!!!!!!!!      only for your viewing pleasure' >> defaults.sh
echo '# DISCLAIMER!!!!!!!!' >> defaults.sh
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

popd || exit
