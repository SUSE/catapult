#!/bin/bash

. scripts/include/common.sh
. .envrc

set -euo pipefail

kubectl create namespace bkindwscf || true
kubectl create -f ../kube/task.yaml || true

bash ../scripts/wait_ns.sh bkindwscf

kubectl cp ../build$CLUSTER_NAME bkindwscf/task:/bkindwscf/
kubectl exec -ti -n bkindwscf task -- /bin/bash -c "CLUSTER_NAME=$CLUSTER_NAME make buildir login" || true

echo "source build$CLUSTER_NAME/.envrc" > .bashrc
kubectl cp .bashrc bkindwscf/task:/bkindwscf/
rm -rf .bashrc

echo
echo "@@@@@@@@@@@@@@"
echo "Executing into the persistent pod"
echo "You can already use 'cf' and 'kubectl'"
echo "Note: After you are done, you need to remove it explictly with: kubectl delete pod -n bkindwscf task"
echo "@@@@@@@@@@@@@@"
echo

exec kubectl exec -ti task -n bkindwscf -- /bin/bash -l -c "source build$CLUSTER_NAME/.envrc && /bin/bash"