#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

cp "$KUBECFG" kubeconfig

if ! aws sts get-caller-identity ; then
    info "Missing aws credentials, running aws configure…"
    # Use predefined aws env vars
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
    aws configure
fi

kubectl get nodes  > /dev/null 2>&1 || exit

ok "Kubeconfig for $BACKEND correctly imported"
