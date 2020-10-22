#!/usr/bin/env bash

# Requires:
# - gcloud credentials present
# - jq

# OPTIONS:
# GKE_CRED_JSON gcloud credentials
# GKE_PROJECT   gcloud project
# OWNER         The owner of the clusters to filter on
# OUTPUT_FILE   File to output to; outputs to standard out if not set.

. ./defaults.sh
. ../../include/common.sh
# Do not require .envrc

# check gcloud credentials:
info "Using creds from GKE_CRED_JSON…"
gcloud auth revoke 2>/dev/null || true
gcloud auth activate-service-account --project "$GKE_PROJECT" --key-file "$GKE_CRED_JSON"
if [[ $(gcloud auth list  --format="value(account)" | wc -l ) -le 0 ]]; then
    err "GKE_CRED_JSON creds don't authenticate, aborting" && exit 1
fi

info "Listing GKE clusters…"

# List all clusters; we don't filter here to better find orphaned resources.
all_cluster_names="$(
    gcloud container clusters list --format='get(name)' \
        --filter="location:('${GKE_LOCATION}')"
    )"
# only clusters that we might want to delete
clusters="$(
    gcloud container clusters list --format='json(name,resourceLabels)' \
        --filter="
            location:('${GKE_LOCATION}')
            resourceLabels.owner:('${OWNER}')
        ")"

# List all addresses that are not in use
addresses="$(
    gcloud compute addresses list --format='json(name)' \
        --filter="
            -status:('IN_USE')
            region:('${GKE_LOCATION%-[abcdef]}')
    ")"

# This is a Python regular expression to match a GUID
guid_re='(?i:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
# List all (PVC) disks not attached to a cluster
# Note that PVCs do _not_ get a `owner` label
disk_cluster_filter="$(for cluster in ${all_cluster_names}; do
    # The disk name is "gke-<cluster name>-<random>" + "-pvc-<guid>"
    # where the first part is truncated if too long (more than 22 characters).
    cluster_prefix="gke-${cluster}"
    if [[ "${#cluster_prefix}" -lt 22 ]]; then
        cluster_prefix="${cluster_prefix}-[^-]*"
    else
        cluster_prefix="${cluster_prefix:0:22}"
    fi
    printf -- '-name~"^%s-pvc-%s$"\n' "${cluster_prefix}" "${guid_re}"
done)"
disks="$(
    gcloud compute disks list --format='json(name,description,labels)' --filter="
        description~kubernetes.io/created-for/pv/name
        zone:('${GKE_LOCATION%-[abcdedf]}')
        ( labels.owner:('${OWNER}') OR -labels.owner:* )
        name~\"^gke-kubecf-.*-pvc-${guid_re}\$\"
        ${disk_cluster_filter}
    ")"

combined="{\"clusters\": ${clusters}, \"addresses\": ${addresses}, \"disks\": ${disks}}"

if [[ -n "${OUTPUT_FILE}" ]]; then
    exec >"${OUTPUT_FILE}"
fi

# For clusters, rename .resourceLabels to .labels for consistency
jq '.clusters |= map( {name: .name, labels: .resourceLabels} )' \
    <(echo "${combined}")
