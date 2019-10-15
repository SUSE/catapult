#!/usr/bin/env bash

# Destroys an existing Caasp4 cluster on openstack
#
# Requirements:
# - Built skuba docker image
# - Sourced openrc.sh
# - Key on the ssh keyring

. "$( dirname "${BASH_SOURCE[0]}" )"/caasp4os.sh
. "$( dirname "${BASH_SOURCE[0]}" )"/lib/skuba.sh
. ../../include/common.sh
. .envrc

set -exuo pipefail


if [ -d "$BUILD_DIR" ]; then
    if [[ ! -v OS_PASSWORD ]]; then
        echo ">>> Missing openstack credentials" && exit 1
    fi

    . .envrc
    if kubectl get storageclass 2>/dev/null | grep -qi persistent; then
        # destroy storageclass, allowing nfs server to delete the share
        kubectl delete storageclass persistent
        wait
    fi

    if [ -d deployment ]; then
        pushd deployment
        # destroy terraform openstack stack
        skuba_container terraform destroy -auto-approve
        popd
    fi

    popd
    rm -rf "$BUILD_DIR"
fi

