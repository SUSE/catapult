#!/bin/bash

. ../../include/common.sh
. .envrc

# Kind above version 0.6.0 generates the config itself
if [ ! -f kubeconfig ]; then
  cp $(kind get kubeconfig-path --name="$CLUSTER_NAME") kubeconfig

  ok "Kubeconfig copied"
fi
