#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig

helm install helm/uaa --name susecf-uaa --namespace uaa --values scf-config-values.yaml

#watch -c 'kubectl get pods --namespace uaa'
bash ../scripts/wait.sh uaa

SECRET=$(kubectl get pods --namespace uaa \
-o jsonpath='{.items[?(.metadata.name=="uaa-0")].spec.containers[?(.name=="uaa")].env[?(.name=="INTERNAL_CA_CERT")].valueFrom.secretKeyRef.name}')

CA_CERT="$(kubectl get secret $SECRET --namespace uaa \
-o jsonpath="{.data['internal-ca-cert']}" | base64 --decode -)"

helm install helm/cf --name susecf-scf --namespace scf \
--values scf-config-values.yaml \
--set "secrets.UAA_CA_CERT=${CA_CERT}"

#watch kubectl get pods -n scf

bash ../scripts/wait.sh scf
