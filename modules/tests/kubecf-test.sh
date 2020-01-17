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

timeout="300"
pushd "$KUBECF_CHECKOUT"
    # FIXME: See how to pass those options to bazel commands - we make it not to fail to be idempotent but we edit user files on git checkout (BAD!)
    sed -i 's/namespace = "kubecf"/namespace = "'"$KUBECF_NAMESPACE"'"/' def.bzl || true
    sed -i 's/deployment_name = "kubecf"/deployment_name =  "'"$KUBECF_DEPLOYMENT_NAME"'"/' def.bzl || true
    if [ "${KUBECF_TEST_SUITE}" == "smokes" ]; then
        bazel run //testing/smoke_tests
        info "Waiting for the smoke-tests pod to start..."
        until smoke_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
        if [[ "${timeout}" == 0 ]]; then return 1; fi
        pod_name="$(smoke_tests_pod_name)"
        container_name="smoke-tests-smoke-tests"
    else
        bazel run //testing/acceptance_tests
        info "Waiting for the acceptance-tests pod to start..."
        until cf_acceptance_tests_pod_name || [[ "$timeout" == "0" ]]; do sleep 1; timeout=$((timeout - 1)); done
        if [[ "${timeout}" == 0 ]]; then return 1; fi
        pod_name="$(cf_acceptance_tests_pod_name)"
        container_name="acceptance-tests-acceptance-tests"
    fi
popd

wait_for_tests_pod "$pod_name" "$container_name" || {
>&2 err "Timed out waiting for the tests pod"
exit 1
}

# Follow the logs. If the tests fail, or container exits it will move on (with all logs printed)
kubectl logs -f "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container "$container_name" ||:

# Wait for the container to terminate and then exit the script with the container's exit code.
jsonpath='{.status.containerStatuses[?(@.name == "'"$container_name"'")].state.terminated.exitCode}'
while true; do
exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
if [[ -n "${exit_code}" ]]; then
    exit "${exit_code}"
fi
sleep 1
done