#!/usr/bin/env bash
set -e

# Usage ./create-qa-config.sh [${QA_ADMIN_NS}]
# Creates 'qa-sa' (or $1) namespace and clusterrolebinding so its default SA has cluster admin permissions
# Outputs a config that can be used for pipeline without fear of revocation

QA_ADMIN_NS=${1:-qa-sa}

TEMPDIR=$( mktemp -d )

trap "{ rm -rf ${TEMPDIR} ; exit 255; }" EXIT

kubectl apply -f - << EOF
---
kind: Namespace
apiVersion: v1
metadata:
  name: ${QA_ADMIN_NS}
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: ${QA_ADMIN_NS}:default
subjects:
- kind: ServiceAccount
  name: default
  namespace: ${QA_ADMIN_NS}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
EOF

SA_SECRET=$( kubectl get sa -n ${QA_ADMIN_NS} default -o jsonpath='{.secrets[0].name}' )

# Adapted from https://gist.github.com/ericchiang/d2a838ddad3f44436ae001a342e1001e
# Shared as part of https://github.com/coreos/dex/issues/1111:

# Get bearer token and cluster CA from qa-sa service account secret.
BEARER_TOKEN=$( kubectl get secrets -n ${QA_ADMIN_NS} ${SA_SECRET} -o jsonpath='{.data.token}' | base64 -d )

kubectl get secrets -n ${QA_ADMIN_NS} ${SA_SECRET} -o jsonpath='{.data.ca\.crt}' | base64 -d > ${TEMPDIR}/ca.crt

CLUSTER_URL=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

KUBECONFIG=${TEMPDIR}/config

kubectl config --kubeconfig=${KUBECONFIG} set-cluster local \
  --server=${CLUSTER_URL} \
  --certificate-authority=${TEMPDIR}/ca.crt \
  --embed-certs=true

kubectl config --kubeconfig=${KUBECONFIG} set-credentials default \
  --token=${BEARER_TOKEN}

kubectl config --kubeconfig=${KUBECONFIG} set-context concourse \
  --cluster=local \
  --user=default

kubectl config --kubeconfig=${KUBECONFIG} use-context concourse

cat ${KUBECONFIG} >> $(pwd | sed -e 's|/.*./||g' -e 's|-cluster||g')
