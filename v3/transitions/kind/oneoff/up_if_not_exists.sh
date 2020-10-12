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
replicas: 1
extraMounts:
- containerPath: /code
  hostPath: ${APPLICATION_PATH}
  # readOnly: true
EOF

if [ -n "$EKCP_HOST" ]; then
    error=$(curl http://$EKCP_HOST/api/v1/cluster/${CLUSTER_NAME}/info | jq -r .Error)

    # We get an error if the cluster doesn't exist. In that case, create it.
    if [ "${error}" != "null" ]; then
      echo "Remote cluster doesn't exist, creating now"
      curl -d "name=${CLUSTER_NAME}" -X POST http://$EKCP_HOST/new
    else
      echo "Remote cluster already exists, skipping creation"
    fi
else
  if [ -z "$(kind get clusters | grep ${CLUSTER_NAME})" ]; then
    echo "Local cluster doesn't exist, creating now"
    kind create cluster --config kind-config.yaml --name=${CLUSTER_NAME}
  else
    echo "Local cluster already exists, skipping creation"
  fi
fi
