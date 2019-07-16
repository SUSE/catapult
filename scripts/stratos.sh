#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig

helm repo add suse https://kubernetes-charts.suse.com/

helm install suse/console \
    --name susecf-console \
    --namespace stratos \
    --values scf-config-values.yaml

bash ../scripts/wait.sh stratos
