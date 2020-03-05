#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


info "Deploying gitea from the helm charts"
domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')


helm delete gitea --purge || true
helm repo add jfelten https://luqasn.github.io/gitea-helm-chart


cat > gitea-config-values.yaml <<EOF
service:
  http:
    serviceType: NodePort
    port: 3000
    nodePort: 30080
    externalPort: 8280
    externalHost: ${domain}
  ssh:
    serviceType: NodePort
    port: 22
    nodePort: 30222
    externalPort: 8022
    externalHost: ${domain}

EOF

kubectl create namespace "gittea" || true
helm_install gitea jfelten/gitea --values gitea-config-values.yaml --namespace gittea
wait_ns gittea

if [ "$BACKEND" == "ekcp" ]; then
  PODNAME=$(kubectl get pods -n gittea -l app=gitea-gitea -o jsonpath="{.items[0].metadata.name}")
  info "Inside the cluster, gitea is reachable at http://${domain}:30080 ssh://git@${domain}:30222"
  info "To access it from your local machine, run:"
  info "for http access (to local http://127.0.0.1:8080): kubectl port-forward --namespace gittea $PODNAME 8080:3000"
  info "for ssh access (to local ssh://git@127.0.0.1:2222): kubectl port-forward --namespace gittea $PODNAME 2222:22"
else
  info "Gitea installed: http://${domain}:30080 ssh://git@${domain}:30222"
fi

info "Go to the gitea webui and finish the setup."
warn "Mind to setup the SSH Server port to 30222 and the Gitea Base URL as http://${domain}:30080/"


info "If you plan to use it with drone:"
info "1. Go to http://${domain}:30080/user/settings/applications"
info "2. Create a new application, name it drone, redirect uri is: http://${domain}:32011/login"
info "Use those secrets for DRONE_CLIENT_ID and DRONE_CLIENT_SECRET when running module-extra-drone"
