#!/bin/bash

. ../../include/common.sh
. .envrc


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

ok "Cluster is up"
