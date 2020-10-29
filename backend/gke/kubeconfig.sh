#!/usr/bin/env bash

# KUBECFG can be a kubeconfig file or a cluster reference file for local deployments
# KUBECFG has to be a kubeclusterreference for CI usage, check gke/deploy.sh for format
if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

if [[ $(yq r ${KUBECFG} kind) == "ClusterReference" ]]; then
    # Process kubeclusterreference file
    echo "Using kubeclusterreference ..."
    GKE_CLUSTER_NAME="$(yq r ${KUBECFG} cluster-name)"
    GKE_CLUSTER_ZONE="$(yq r ${KUBECFG} cluster-zone)"
    GKE_PROJECT="$(yq r ${KUBECFG} project)"
    export GKE_CLUSTER_NAME GKE_CLUSTER_ZONE GKE_PROJECT
elif [[ $(yq r ${KUBECFG} kind) == "Config" ]]; then
    echo "Using kubeconfig ..."
else
    echo "Please check your KUBECFG"
    exit 1
fi

. ./defaults.sh
. ../../include/common.sh
. .envrc
. "${ROOT_DIR}/backend/gke/lib/auth.sh"

gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --zone ${GKE_CLUSTER_ZONE}

# kubeconfig gets hardcoded paths for gcloud bin, reevaluate them:
gcloud_path="$(which gcloud)"
gcloud_path_esc=$(echo "$gcloud_path" | sed 's_/_\\/_g')
sed -e "s/\(cmd-path\: \).*/\1$gcloud_path_esc/" kubeconfig > kubeconfig.bkp
mv kubeconfig.bkp kubeconfig

kubectl get nodes 1> /dev/null || exit

ok "Kubeconfig for $BACKEND correctly imported"
