#!/usr/bin/env bash

if [ ! -f "$KUBECFG" ]; then
    err "No KUBECFG given - you need to pass one!"
    exit 1
fi
# usage: read_yaml_key test.yaml key-name
read_yaml_key() {
    ruby -r yaml -e "puts YAML.load_file('$1')[\"$2\"]"
}

# Process ClusterReference file
ClusterReference_file=$KUBECFG
GKE_CLUSTER_NAME="$(read_yaml_key ${ClusterReference_file} cluster-name)"
export GKE_CLUSTER_NAME
GKE_CLUSTER_ZONE="$(read_yaml_key ${ClusterReference_file} cluster-zone)"
export GKE_CLUSTER_ZONE
GKE_PROJECT_ID="$(read_yaml_key ${ClusterReference_file} project)"
export GKE_PROJECT_ID

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
