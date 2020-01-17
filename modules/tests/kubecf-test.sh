#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

smoke_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "smoke-tests"
}

cf_acceptance_tests_pod_name() {
  kubectl get pods --namespace "${KUBECF_NAMESPACE}" --output name 2> /dev/null | grep "acceptance-tests"
}

# Wait for smoke-tests to start.
wait_for_tests_pod() {
  local podname=$1
  local containername=$2
  local timeout="300"
  until [[ "$(kubectl get "${podname}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "'"$containername"'")].state.running}' 2> /dev/null)" != "" ]] || [[ "$(kubectl get "${podname}" --namespace "${KUBECF_NAMESPACE}" --output jsonpath='{.status.containerStatuses[?(@.name == "smoke-tests-smoke-tests")].state.terminated}' 2> /dev/null)" != "" ]]  || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
  if [[ "${timeout}" == 0 ]]; then return 1; fi
  return 0
}

# Delete any pending job
kubectl delete jobs -n "${KUBECF_NAMESPACE}"  --all || true

pushd "$KUBECF_CHECKOUT"
    sed -i 's/namespace = "kubecf"/namespace = "'"$KUBECF_NAMESPACE"'"/' def.bzl
    sed -i 's/deployment_name = "kubecf"/deployment_name =  "'"$KUBECF_DEPLOYMENT_NAME"'"/' def.bzl
    if [ "${KUBECF_TEST_SUITE}" == "smokes" ]; then
        bazel run //testing/smoke_tests
    else
        bazel run //testing/acceptance_tests
    fi
popd

timeout="300"
if [ "${KUBECF_TEST_SUITE}" == "smokes" ]; then
    info "Waiting for the smoke-tests pod to start..."
    until smoke_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(smoke_tests_pod_name)"
    container_name="smoke-tests-smoke-tests"
else 
    info "Waiting for the acceptance-tests pod to start..."
    until cf_acceptance_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
    if [[ "${timeout}" == 0 ]]; then return 1; fi
    pod_name="$(cf_acceptance_tests_pod_name)"
    container_name="acceptance-tests-acceptance-tests"
fi

wait_for_tests_pod "$pod_name" "$container_name" || {
>&2 err "Timed out waiting for the smoke-tests pod"
exit 1
}

# Follow the logs. If the tests fail, the logs command will also fail.
kubectl attach "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container "$container_name" ||:

# Wait for the container to terminate and then exit the script with the container's exit code.
jsonpath='{.status.containerStatuses[?(@.name == "'"$containername"'")].state.terminated.exitCode}'
while true; do
exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
if [[ -n "${exit_code}" ]]; then
    exit "${exit_code}"
fi
sleep 1
done