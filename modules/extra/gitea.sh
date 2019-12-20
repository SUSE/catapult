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

helm install --values gitea-config-values.yaml --name gitea --namespace gittea jfelten/gitea
bash "$ROOT_DIR"/include/wait_ns.sh gittea
info "Gitea installed: http://${domain}:30080 ssh://git@${domain}:30222"

info "Go to the gitea webui and finish the setup."
warn "Mind to setup the SSH Server port to 30222 and the Gitea Base URL as http://${domain}:30080/"

info "If you plan to use it with drone:"
info "1. Go to http://${domain}:30080/user/settings/applications"
info "2. Create a new application, name it drone, redirect uri is: http://${domain}:32011/login"
info "Use those secrets for DRONE_CLIENT_ID and DRONE_CLIENT_SECRET"
