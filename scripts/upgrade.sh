#!/bin/bash

set -ex 

. scripts/include/common.sh

SECRET=$(kubectl get pods --namespace uaa \
-o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
-o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm upgrade susecf-scf helm/cf/ --values scf-config-values.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

bash ../scripts/wait.sh scf
