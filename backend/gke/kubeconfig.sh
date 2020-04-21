#!/usr/bin/env bash

# KUBECFG can be a kubeconfig file or a cluster reference file for local deployments
# KUBECFG has to be a ClusterReference.yaml for CI usage, check gke/deploy.sh for format
if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi

if grep -Fxq "kind: ClusterReference" ${KUBECFG}; then
    # Process ClusterReference file
    echo "Processing ClusterReference.yaml ..."
    ClusterReference_file=$KUBECFG
    GKE_CLUSTER_NAME="$(yq r ${ClusterReference_file} cluster-name)"
    export GKE_CLUSTER_NAME
    GKE_CLUSTER_ZONE="$(yq r ${ClusterReference_file} cluster-zone)"
    export GKE_CLUSTER_ZONE
    GKE_PROJECT="$(yq r ${ClusterReference_file} project)"
    export GKE_PROJECT
else
    echo "ClusterReference.yaml is not of correct format or has not been provided"
    echo "Processing $KUBECFG as a kubeconfig.yaml ..."
fi

. ./defaults.sh
. ../../include/common.sh
. .envrc

# check gcloud credentials:
info "Using creds from GKE_CRED_JSON…"
gcloud auth revoke 2>/dev/null || true
gcloud auth activate-service-account --project "$GKE_PROJECT" --key-file "$GKE_CRED_JSON"
if [[ $(gcloud auth list  --format="value(account)" | wc -l ) -le 0 ]]; then
    err "GKE_CRED_JSON creds don't authenticate, aborting" && exit 1
fi
gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --zone ${GKE_CLUSTER_ZONE}

# kubeconfig gets hardcoded paths for gcloud bin, reevaluate them:
gcloud_path="$(which gcloud)"
gcloud_path_esc=$(echo "$gcloud_path" | sed 's_/_\\/_g')
sed -e "s/\(cmd-path\: \).*/\1$gcloud_path_esc/" kubeconfig > kubeconfig.bkp
mv kubeconfig.bkp kubeconfig

kubectl get nodes 1> /dev/null || exit

ok "Kubeconfig for $BACKEND correctly imported"
