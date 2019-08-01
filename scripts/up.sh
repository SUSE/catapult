#!/bin/bash
set -x
. scripts/include/common.sh

pushd build${CLUSTER_NAME}
    APPLICATION_PATH=$PWD

    cat > kind-config.yaml <<EOF
kind: Config
apiVersion: kind.sigs.k8s.io/v1alpha2
nodes:
- role: control-plane
  replicas: 1
  extraMounts:
    - containerPath: /code
      hostPath: ${APPLICATION_PATH}
      # readOnly: true
EOF
    ./kind create cluster --config kind-config.yaml --name=${cluster_name}
popd
