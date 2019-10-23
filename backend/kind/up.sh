#!/bin/bash

. ../../include/common.sh
. .envrc

set -Eeo pipefail

debug_mode

APPLICATION_PATH=$PWD
type="Config"
if [ "${KIND_APIVERSION}" == "kind.sigs.k8s.io/v1alpha3" ]; then
    type="Cluster"
fi
cat > kind-config.yaml <<EOF
kind: $type
apiVersion: ${KIND_APIVERSION}
nodes:
- role: control-plane
  extraMounts:
  - containerPath: /code
    hostPath: ${APPLICATION_PATH}
    # readOnly: true
EOF

kind create cluster --config kind-config.yaml --name=${CLUSTER_NAME}

# Trust the kubernetes ca on the node so CF application containers can be pulled
# from the registry (otherwise it fails because the ca is not trusted).
docker exec -it ${CLUSTER_NAME} bash -c 'cp /etc/kubernetes/pki/ca.crt /etc/ssl/certs/ && update-ca-certificates && systemctl restart containerd'

ok "Cluster is up"
