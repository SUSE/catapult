#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

curl http://"$EKCP_HOST"/kubeconfig/"${CLUSTER_NAME}" > kubeconfig
ok "Kubeconfig for $BACKEND correctly imported"
