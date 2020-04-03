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

isolate_network() {
    enable="${1:-1}"

    if [[ $enable == 1 ]]; then
      # Complaint wrong. The echo generates a traling newline the `blue` doesn't.
      # shellcheck disable=SC2005
      echo "$(blue "Configure cluster network: Deny egress external")"
      # enable isolation
      # ingress - allows all incoming traffic
      # egress  - allows dns traffic anywhere
      #         - allows traffic to all ports, pods, namespaces
      #           (but no whitelisting of external ips!)
      # references
      # - BASE = https://github.com/ahmetb/kubernetes-network-policy-recipes
      # - (BASE)/blob/master/02a-allow-all-traffic-to-an-application.md
      # - (BASE)/blob/master/14-deny-external-egress-traffic.md
      # - See also https://www.youtube.com/watch?v=3gGpMmYeEO8 (31min)
      #   - Egress info wrt disallow external see 17:20-17:52
      #
      # __ATTENTION__
      # Requires a networking plugin to enforce, else ignored
      # (if not directly supported by platform)
      # - Example plugins: Calico, WeaveNet, Romana
      #
      # GKE: Uses Calico, Use `--enable-network-policy` when
      # creating a cluster (`gcloud`).
      # Minikube needs special setup.
      # KinD used by our Drone setup may have support.

      cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: cats-internetless
  namespace: ${KUBECF_NAMESPACE}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - {}
  egress:
    - ports:
      - port: 53
        protocol: UDP
      - port: 53
        protocol: TCP
    - to:
      - namespaceSelector: {}
EOF
      # For debugging, show what kube thinks of it.
      kubectl describe networkpolicies \
        --namespace "${KUBECF_NAMESPACE}" \
        cats-internetless
    else
      # shellcheck disable=SC2005
      echo "$(blue "Configure cluster network: Full access")"
      # disable isolation
      kubectl delete networkpolicies \
        --namespace "${KUBECF_NAMESPACE}" \
        cats-internetless
    fi
}

create_cats_internetless_secret() {
  info "Creating cats secret to use internetless CATS test suite"
  cats_secret_name="$(
    kubectl get qjobs -n "${KUBECF_NAMESPACE}" \
    "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests -o json | \
    jq -r '.spec.template.spec.template.spec.volumes[] | select(.name=="ig-resolved").secret.secretName')"

  cats_secret="$(kubectl get secrets --export -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o yaml)"

  cats_updated_properties="$(
    kubectl get secret -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o json  | \
    jq -r '.data."properties.yaml"' | base64 -d | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.include" '=internetless' | \
    base64 -w 0 )"

    cats_updated="$(echo "$cats_secret" | yq w - 'data[properties.yaml]' $cats_updated_properties)"
    cats_updated="$(echo "$cats_updated" | yq w - 'metadata.name' 'cats-internetless')"
    kubectl apply -f <(echo "${cats_updated}") -n "${KUBECF_NAMESPACE}"
}

mount_cats_internetless_secret() {
  original_volumes=$(
    kubectl get qjob "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests --namespace "${KUBECF_NAMESPACE}" -o json | \
    jq -r '.spec.template.spec.template.spec.volumes')

  updated_volumes=$(echo ${original_volumes} | \
    jq -r 'map((select(.name=="ig-resolved") | .secret.secretName) |= "cats-internetless")')

  patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${updated_volumes}' } } } } } }'
  revert_patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${original_volumes}' } } } } } }'

  # Mount the original secret again in case "normal" cats are run after the internetless cats.
  function internetless_revert {
    kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${revert_patch}"
  }
  trap internetless_revert EXIT

  kubectl patch qjob "${KUBECF_DEPLOYMENT_NAME}"-acceptance-tests \
    --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${patch}"
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
  cats-internetless)
    isolate_network 1
    create_cats_internetless_secret
    mount_cats_internetless_secret

    # Allow network traffic again.
    trap 'isolate_network 0' EXIT

    trigger_test_suite acceptance-tests
    pod_name="$(get_resource_name pod acceptance-tests)"
    container_name="acceptance-tests-acceptance-tests"
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
exit_code=""
while [[ -z "${exit_code}" ]]; do
    exit_code="$(kubectl get "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --output "jsonpath=${jsonpath}")"
    sleep 1
done

# save results of tests to file
mkdir -p artifacts
log="artifacts/$(date +'%Y-%m-%d-%H:%M')_${pod_name#*/}.log"
kubectl logs "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container "$container_name" > "${log}"

if [ "${exit_code}" -ne 0 ]; then
    err "${KUBECF_TEST_SUITE} failed"
    exit "${exit_code}"
fi
# remove job, tests were successful
kubectl delete jobs -n "${KUBECF_NAMESPACE}"  --all --wait || true

ok "${KUBECF_TEST_SUITE} passed"
