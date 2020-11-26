#!/usr/bin/env bash

# Requires:
# - gcloud credentials present
# - jq

# OPTIONS:
# GKE_CRED_JSON gcloud credentials
# GKE_LOCATION  gcloud AZ
# GKE_PROJECT   gcloud project
# GKE_DNSDOMAIN Example name of clusters to clean up
# OWNER         The owner of the clusters to filter on
# OUTPUT_FILE   File to output to; outputs to standard out if not set.

. ./defaults.sh
. ../../include/common.sh
. .envrc
. "${ROOT_DIR}/backend/gke/lib/auth.sh"

info "Listing GKE clusters…"

# List all clusters; we don't filter here to better find orphaned resources.
all_clusters="$(
    gcloud container clusters list --format='json(name,resourceLabels)' \
        --filter="
            location:('${GKE_LOCATION}')
        ")"
all_cluster_names="$(jq -r '.[] | .name' <<< "${all_clusters}")"

info "Listing GKE IP addresses…"

# List all addresses that are not in use
addresses="$(
    gcloud compute addresses list --format='json(name)' \
        --filter="
            -status:('IN_USE')
            region:('${GKE_LOCATION%-[abcdef]}')
    ")"

info "Listing GKE disks…"

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
        zone:('${GKE_LOCATION}')
        -users:*
        ( labels.owner:('${OWNER}') OR -labels.owner:* )
        name~\"^gke-kubecf-.*-pvc-${guid_re}\$\"
        ${disk_cluster_filter}
    ")"

info "Listing GKE DNS entries…"

# Find all managed DNS zones
dns_zones="$(gcloud dns managed-zones list --format='json(name,dnsName)')"
# Find the longest zone that is a suffix of the GKE_DNSDOMAIN
dns_zone="$(
    jq <<<"${dns_zones}" --raw-output --arg domain "${GKE_DNSDOMAIN%.}." '
        # Find all zones that are a suffix of the given $domain
        map(select(
            .dnsName as $suffix
            | $domain | endswith($suffix)
        ))
        # Sort all zones, longest first
        | sort_by(-(.dnsName | length))
        # Keep only the first one, and return its name
        | .[0].name
        '
    )"
# List all DNS record sets in that zone
recordsets="$(gcloud dns record-sets list --zone="${dns_zone}" --format='json')"
# The clusters we want to clean up after has this prefix
expected_prefix="kubecf-ci-$(tr --delete --complement A-Za-z0-9 <<< "${OWNER}")-"
# Filter DNS record sets that are external DNS.  We don't filter by owner here,
# and do it when we do the actual cleaning.
dns_entries="$(
    jq --arg prefix "${expected_prefix}" <<<"${recordsets}" '
        . as $root
        | map(
            select(.type == "TXT")
            # Parse the metadata out of the rrdatas (TXT entries)
            | (
                .rrdatas[]
                # Find the entry with external-dns information
                | select(contains("heritage=external-dns"))
                | fromjson
                | split(",")
                # Convert comma-separated into key/value mapping
                | map(capture("(?<key>[^=]+)=(?<value>.*)"))
                | from_entries
            ) as $info
            | {name: .name, info: $info}
        )
        | map(select(.info["external-dns/owner"] | startswith($prefix)))
        | map(
            .name as $name
            | .recordsets = ($root | map(select(.name == $name)))
        )
    '
    )"

if [[ -n "${OUTPUT_FILE:-}" ]]; then
    exec >"${OUTPUT_FILE}"
fi

# For clusters, rename .resourceLabels to .labels for consistency
jq --argjson clusters "${all_clusters}" \
   --argjson addresses "${addresses}" \
   --argjson disks "${disks}" \
   --arg     dns_zone "${dns_zone}" \
   --argjson dns_entries "${dns_entries}" \
   '.clusters = ($clusters | map({name: .name, labels: .resourceLabels}))
    | .addresses = $addresses
    | .disks = $disks
    | .dns = { zone: $dns_zone, entries: $dns_entries }
    ' <<< '{}'
