#!/bin/bash
set -ex

. ../../include/common.sh
. .envrc

cp $(kind get kubeconfig-path --name="$CLUSTER_NAME") kubeconfig

ok "Kubeconfig copied"