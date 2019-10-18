#!/bin/bash

set -e

. ../../include/common.sh
. .envrc

debug_mode

if [ -n "$SCF_CHART" ]; then
# save SCF_CHART on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
fi

SECRET=$(kubectl get pods --namespace uaa \
-o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret "$SECRET" --namespace uaa \
-o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

if [ "$UAA_UPGRADE" == true ]; then

    helm upgrade --recreate-pods susecf-uaa helm/uaa/ --values scf-config-values.yaml \
    --set "secrets.UAA_CA_CERT=${CA_CERT}"

    bash "$ROOT_DIR"/include/wait_ns.sh uaa

fi

helm upgrade --recreate-pods susecf-scf helm/cf/ --values scf-config-values.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

bash "$ROOT_DIR"/include/wait_ns.sh scf

ok "SCF deployment upgraded successfully"
