#!/bin/bash

. ./defaults.sh
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
networking:
  disableDefaultCNI: true
EOF

kind create cluster --config kind-config.yaml --name=${CLUSTER_NAME}

# TODO: Run this somewhere to enable weave network plugin:
kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.6.2/weave-daemonset-k8s-1.11.yaml

ok "Cluster is up"
