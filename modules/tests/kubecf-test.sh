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
        --ignore-not-found \
        cats-internetless
    fi
}

create_cats_internetless_secret() {
  info "Creating cats secret to use internetless CATS test suite"

  qjob="$(get_resource_name qjob "acceptance-tests")"
  cats_secret_name="$(
    kubectl get ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
    jq -r '.spec.template.spec.template.spec.volumes[] | select(.name=="ig-resolved").secret.secretName')"

  cats_secret="$(kubectl get secrets --export -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o yaml)"

  cats_updated_properties="$(
    kubectl get secret -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o json  | \
    jq -r '.data."properties.yaml"' | base64 -d | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.include" '=internetless' | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.credhub_mode" 'skip-tests' | \
    base64 -w 0 )"

  cats_updated="$(echo "$cats_secret" | yq w - 'data[properties.yaml]' $cats_updated_properties)"
  cats_updated="$(echo "$cats_updated" | yq w - 'metadata.name' 'cats-internetless')"
  kubectl apply -f <(echo "${cats_updated}") -n "${KUBECF_NAMESPACE}"
}

mount_cats_internetless_secret() {
  qjob="$(get_resource_name qjob "acceptance-tests")"
  original_volumes=$(
    kubectl get ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
    jq -r '.spec.template.spec.template.spec.volumes')

  updated_volumes=$(echo ${original_volumes} | \
    jq -r 'map((select(.name=="ig-resolved") | .secret.secretName) |= "cats-internetless")')

  patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${updated_volumes}' } } } } } }'

  kubectl patch ${qjob} --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${patch}"
}

# Re-enables internet access again and mounts the original secret in the qjob
# to allow internet-full cats.
cleanup_cats_internetless() {
  rv=$?
  isolate_network 0
  revert_patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${original_volumes}' } } } } } }'
  echo "$(blue "Mounting the original secret in acceptance tests qjob")"
  qjob="$(get_resource_name qjob "acceptance-tests")"
  kubectl patch ${qjob} --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${revert_patch}"

  kubectl delete secret -n ${KUBECF_NAMESPACE} --ignore-not-found cats-internetless
  trap "exit \$rv" EXIT
}

create_cats_eirini_secret() {
  info "Creating cats secret to use in Eirini CATS test suite"

  qjob="$(get_resource_name qjob "acceptance-tests")"
  cats_secret_name="$(
    kubectl get ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
    jq -r '.spec.template.spec.template.spec.volumes[] | select(.name=="ig-resolved").secret.secretName')"

  cats_secret="$(kubectl get secrets --export -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o yaml)"
  # This is what upstream Eirini was running and was green:
  # https://github.com/cloudfoundry-incubator/eirini-ci/blob/09dcce6d9e900f693dfc1a6da70b5a526cf7de18/pipelines/dhall-modules/jobs/run-core-cats.dhall#L52-L86

  # Normally, it only makes sense to disable test groups that are enabled by default
  # and enable those that aren't:
  # https://github.com/cloudfoundry/cf-acceptance-tests#test-configuration
  # Below we keep the full (explicit) list though, to make it easier to switch
  # groups on and off.
  suites=$(paste -d',' -s <(cat <<-SUITES
+apps
capi_no_bridge
container_networking
detect
docker
internet_dependent
routing
sso
v3
zipkin
ssh
-backend_compatibility
deployments
isolation_segments
private_docker_registry
route_services
routing_isolation_segments
security_groups
services
service_discovery
service_instance_sharing
tasks
SUITES
))

  cats_updated_properties="$(
    kubectl get secret -n "${KUBECF_NAMESPACE}" "${cats_secret_name}" -o json  | \
    jq -r '.data."properties.yaml"' | base64 -d | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.include" "${suites}" | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.stacks" "[sle15]" | \
    yq w - "instance_groups.(name==acceptance-tests).jobs.(name==acceptance-tests).properties.acceptance_tests.credhub_mode" 'skip-tests' | \
    base64 -w 0 )"

  cats_updated="$(echo "$cats_secret" | yq w - 'data[properties.yaml]' $cats_updated_properties)"
  cats_updated="$(echo "$cats_updated" | yq w - 'metadata.name' 'cats-eirini')"
  kubectl apply -f <(echo "${cats_updated}") -n "${KUBECF_NAMESPACE}"
}

mount_cats_eirini_secret() {
  qjob="$(get_resource_name qjob "acceptance-tests")"
  original_volumes=$(
    kubectl get ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
    jq -r '.spec.template.spec.template.spec.volumes')

  updated_volumes=$(echo ${original_volumes} | \
    jq -r 'map((select(.name=="ig-resolved") | .secret.secretName) |= "cats-eirini")')

  patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${updated_volumes}' } } } } } }'

  kubectl patch ${qjob} --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${patch}"
}

# Mounts the original secret in the qjob
cleanup_cats_eirini() {
  rv=$?
  revert_patch='{ "spec": { "template": { "spec": { "template": { "spec": { "volumes": '${original_volumes}' } } } } } }'
  echo "$(blue "Mounting the original secret in acceptance tests qjob")"
  qjob="$(get_resource_name qjob "acceptance-tests")"
  kubectl patch ${qjob} --namespace "${KUBECF_NAMESPACE}" --type merge --patch "${revert_patch}"

  kubectl delete secret -n ${KUBECF_NAMESPACE} --ignore-not-found cats-eirini
  trap "exit \$rv" EXIT
}

# This function should be used to cleanup any old (left-over) pods and jobs from
# previous runs. quarks job deletes the job but doesn't always delete the pod
# (needs the "delete: pod" label to be set).
cleanup() {
  kubectl delete jobs -n "${KUBECF_NAMESPACE}"  --all --wait || true

  pod_name="$(get_resource_name pod ${1} || echo '')"
  if [ ! -z "${pod_name}" ]; then
    echo "Found left-over pod: ${pod_name}, deleting it..."
    kubectl delete "${pod_name}" -n "${KUBECF_NAMESPACE}" --wait || true
  fi
}

timeout="300"

case "${KUBECF_TEST_SUITE}" in
  smokes)
    cleanup "smoke-tests"
    trigger_test_suite smoke-tests
    pod_name="$(get_resource_name pod smoke-tests)"
    container_name="smoke-tests-smoke-tests"
    ;;
  sits)
    cleanup "sync-integration-tests"
    trigger_test_suite sync-integration-tests
    pod_name="$(get_resource_name pod sync-integration-tests)"
    container_name="sync-integration-tests-sync-integration-tests"
    ;;
  brain)
    cleanup "brain-tests"
    trigger_test_suite brain-tests
    pod_name="$(get_resource_name pod brain-tests)"
    container_name="acceptance-tests-brain-acceptance-tests-brain"
    ;;
  cats-eirini)
    cleanup "acceptance-tests"
    # Cleanup trap will need this
    qjob="$(get_resource_name qjob "acceptance-tests")"
    original_volumes=$(
      kubectl get --namespace ${KUBECF_NAMESPACE} ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
      jq -r '.spec.template.spec.template.spec.volumes')

    create_cats_eirini_secret
    mount_cats_eirini_secret

    # Allow network traffic again.
    trap cleanup_cats_eirini EXIT

    trigger_test_suite acceptance-tests
    pod_name="$(get_resource_name pod acceptance-tests)"
    container_name="acceptance-tests-acceptance-tests"
    ;;
  cats-internetless)
    cleanup "acceptance-tests"
    # Cleanup trap will need this
    qjob="$(get_resource_name qjob "acceptance-tests")"
    original_volumes=$(
      kubectl get --namespace ${KUBECF_NAMESPACE} ${qjob} --namespace "${KUBECF_NAMESPACE}" -o json | \
      jq -r '.spec.template.spec.template.spec.volumes')

    isolate_network 1
    create_cats_internetless_secret
    mount_cats_internetless_secret

    # Allow network traffic again.
    trap cleanup_cats_internetless EXIT

    trigger_test_suite acceptance-tests
    pod_name="$(get_resource_name pod acceptance-tests)"
    container_name="acceptance-tests-acceptance-tests"
    ;;
  *)
    cleanup "acceptance-tests"
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
log="artifacts/$(date +'%Y-%m-%d-%H-%M')_${pod_name#*/}.log"
kubectl logs "${pod_name}" --namespace "${KUBECF_NAMESPACE}" --container "$container_name" > "${log}"

if [ "${exit_code}" -ne 0 ]; then
    err "${KUBECF_TEST_SUITE} failed"
    exit "${exit_code}"
fi

ok "${KUBECF_TEST_SUITE} passed"
