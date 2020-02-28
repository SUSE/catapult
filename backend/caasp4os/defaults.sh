#!/bin/bash

# Caasp4os options
##################

# Override default GARDEN_ROOTFS_DRIVER for all backends default
if [ "$BACKEND" == "caasp4os" ]; then
    GARDEN_ROOTFS_DRIVER="${GARDEN_ROOTFS_DRIVER:-btrfs}"
fi
CAASP_VER=${CAASP_VER:-"update"} # devel, staging, update, product
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.16.2}"
