#!/bin/bash

. ../../include/common.sh
. .envrc

curl http://$EKCP_HOST/kubeconfig/${CLUSTER_NAME} > kubeconfig
