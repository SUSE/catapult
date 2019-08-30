#!/usr/bin/env bash

# Destroys an existing Caasp4 cluster on openstack
#
# Requirements:
# - Built skuba docker image
# - Sourced openrc.sh
# - Key on the ssh keyring

. scripts/include/caasp4os.sh
. scripts/include/skuba.sh
. scripts/include/common.sh

set -exuo pipefail


if [ -d ../"$BUILD_DIR" ]; then
    if [[ ! -v OS_PASSWORD ]]; then
        echo ">>> Missing openstack credentials" && exit 1
    fi

    . .envrc
    if kubectl get storageclass 2>/dev/null | grep -qi persistent; then
        # destroy storageclass, allowing nfs server to delete the share
        kubectl delete storageclass persistent
        wait
    fi

    pushd deployment
    # destroy terraform openstack stack
    skuba_container terraform destroy -auto-approve
    popd

    popd
    rm -rf "$BUILD_DIR"
fi

