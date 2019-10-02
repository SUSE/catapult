#!/bin/bash

set -ex 

. ../include/common.sh
. .envrc

if [ -n "$CHART_URL" ]; then
# save CHART_URL on cap-values configmap
    kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$CHART_URL'"'
fi

SECRET=$(kubectl get pods --namespace uaa \
-o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
-o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm upgrade --recreate-pods susecf-scf helm/cf/ --values scf-config-values.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

bash "$ROOT_DIR"/scripts/include/wait_ns.sh scf
