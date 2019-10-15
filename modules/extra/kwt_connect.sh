#!/bin/bash
set -e

. ../../include/common.sh
. .envrc

debug_mode

# Credits to drnic
# https://github.com/starkandwayne/bootstrap-gke#cloud-foundry--eirini--quarks
# https://github.com/starkandwayne/bootstrap-gke/blob/master/resources/eirini/kwt.sh

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

: ${CF_NAMESPACE:=scf}
: ${API_IP:=$(kubectl get svc -n ${CF_NAMESPACE} router-gorouter-public --template '{{.spec.clusterIP}}')}
export API_IP

info "Mapping *.${domain} to internal IP ${API_IP}..."
info
info "Login in another terminal with:"
info "[..] make login "
info

sudo -E bin/kwt net start --dns-map ${domain}=${API_IP} --namespace scf
