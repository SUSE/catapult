#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


# KUBECFG can be a kubeconfig file or a zip archive containing a tf directory for local deployments
# KUBECFG has to be a zip archive for CI usage, see eks/deploy.sh for where a suitable file is created (tf-setup.zip)

if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

mtype=$(file --mime-type "$KUBECFG" |awk '{ print $2}')

# Note: Current working directory is the active buildXXX environment, as needed.

if [[ $mtype == "application/zip" ]] ; then
    info "Using Terraform state ..."

    ( cd cap-terraform/eks || exit
      # ATTENTION: The next command overwrites existing files without
      # prompting.
      unzip -o "$KUBECFG"
      # Reactivate/refresh terraform state - Note, we cannot use the
      # my-plan from the zip, as the state is newer by now.
      terraform apply -auto-approve
    )
    # And reconstruct the kubeconfig from it.
    ( cd cap-terraform/eks || exit
      terraform output kubeconfig
    ) > kubeconfig

elif [[ $mtype == "text/plain" ]] ; then
    info "Using kubeconfig ..."

    cp "$KUBECFG" kubeconfig
else
    err "Please check your KUBECFG"
fi

if ! aws sts get-caller-identity ; then
    err "Missing aws credentials, run aws configure"
    # Use predefined aws env vars
    # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html
    exit 1
fi

kubectl get nodes  > /dev/null 2>&1 || exit

ok "Kubeconfig for $BACKEND correctly imported"
