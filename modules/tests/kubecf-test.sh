#!/bin/bash

# This script runs a test suite on kubecf

. ./defaults.sh
. ../../include/common.sh
. .envrc

# Get the name of the resource matching the given pattern
get_resource_name() {
  local resource_type="${1}"
  local pattern="${2}"
  kubectl get "${resource_type}" --namespace "${KUBECF_NAMESPACE}" --output name \
    2> /dev/null | grep "${pattern}"
}

# Run a command repeatedly until it returns success, at one second interval.
# The first argument is the number of tries; the rest are the command to run.
wait_for_timeout() {
  local timeout="${1}"
  shift
  until "${@}" || [[ "${timeout}" == 0 ]]; do
    sleep 1
    timeout=$((timeout - 1))
  done
}

# Start the given test suite, and wait for the pod to exist.
trigger_test_suite() {
  local qjob suite_name="${1}"
  qjob="$(get_resource_name qjob "${suite_name}")"
  kubectl patch "${qjob}" --namespace "${KUBECF_NAMESPACE}" --type merge --patch \
    '{ "spec": { "trigger": { "strategy": "now" } } }'
  info "waiting for the ${suite_name} pod to start..."
  wait_for_timeout 300 get_resource_name pod "${suite_name}"
  [[ "${timeout}" != 0 ]]
}

# Check if the given pod (with a given container) has either started running or
# terminated (in case the run time is very short).
is_pod_started() {
  local pod_name="${1}" container_name="${2}"
  local state jsonpath result
  for state in running terminated ; do
    jsonpath="{.status.containerStatuses[?(@.name == \"$container_name\")].state.${state}}"
    result="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}" 2> /dev/null || true)"
    if [[ -n "${result}" ]] ; then
      return 0
    fi
  done
  return 1
}

# Wait for tests pod to start.
wait_for_tests_pod() {
  local pod_name="${1}" container_name="${2}"
  info "Waiting for container $container_name in $pod_name"
  wait_for_timeout 300 is_pod_started "${pod_name}" "${container_name}"
}

# Delete any pending job
kubectl delete jobs -n "${KUBECF_NAMESPACE}"  --all --wait || true

timeout="300"

case "${KUBECF_TEST_SUITE}" in
  smokes)
    trigger_test_suite smoke-tests
    pod_name="$(get_resource_name pod smoke-tests)"
    container_name="smoke-tests-smoke-tests"
    ;;
  sits)
    trigger_test_suite sync-integration-tests
    pod_name="$(get_resource_name pod sync-integration-tests)"
    container_name="sync-integration-tests-sync-integration-tests"
    ;;
  brain)
    trigger_test_suite brain-tests
    pod_name="$(get_resource_name pod brain-tests)"
    container_name="acceptance-tests-brain-acceptance-tests-brain"
    ;;
  *)
    trigger_test_suite acceptance-tests
    pod_name="$(get_resource_name pod acceptance-tests)"
    container_name="acceptance-tests-acceptance-tests"
    ;;
esac

if ! wait_for_tests_pod "$pod_name" "$container_name" ; then
  >&2 err "Timed out waiting for the tests pod"
  exit 1
fi

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
