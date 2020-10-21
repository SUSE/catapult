#!/bin/bash

. ../../include/common.sh
# defaults.sh needs CLUSTER_PASSWORD:
. "$ROOT_DIR"/modules/tests/defaults.sh
. .envrc


DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
DEPLOYED_CHART=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["chart"]')
admin_pass=$(kubectl get secret --namespace scf \
                     var-cf-admin-password \
                     -o jsonpath='{.data.password}' | base64 --decode)

info
info "@@@@@@@@@"
info "Running BRATs on deployed chart $DEPLOYED_CHART"
info "@@@@@@@@@"
info

kubectl create namespace catapult || true
kubectl delete pod brats -n catapult || true
kubectl create -f "$ROOT_DIR"/kube/dind.yaml -n catapult || true

export BRATS_CF_HOST="api.$DOMAIN"
export PROXY_HOST="$public_ip"
export PROXY_SCHEME="$PROXY_SCHEME"
export BRATS_CF_USERNAME="$BRATS_CF_USERNAME"
export BRATS_CF_PASSWORD="$admin_pass"
export PROXY_PORT="$PROXY_PORT"
export PROXY_USERNAME="$PROXY_USERNAME"
export PROXY_PASSWORD="$PROXY_PASSWORD"
export BRATS_TEST_SUITE="$BRATS_TEST_SUITE"
export CF_STACK="$CF_STACK"
export GINKGO_ATTEMPTS="$GINKGO_ATTEMPTS"
export BRATS_BUILDPACK="$BRATS_BUILDPACK"
export BRATS_BUILDPACK_URL="$BRATS_BUILDPACK_URL"
export BRATS_BUILDPACK_VERSION="$BRATS_BUILDPACK_VERSION"

pod_definition=$(erb "$ROOT_DIR"/kube/brats/pod.yaml.erb)
redacted_pod_definition=$(echo -e "$pod_definition" | sed -e '/COMPOSER/,+1d')
cat <<EOF
Will create this pod (if you see empty values, make sure you defined all the needed env variables) Note: the COMPOSER_GITHUB_OAUTH_TOKEN is redacted:

${redacted_pod_definition}
EOF

kubectl apply -n catapult -f <(echo "${pod_definition}")
wait_ns catapult

wait_container_attached "catapult" "brats"

set +e
mkdir -p artifacts
kubectl logs -f brats -n catapult > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_brats.log
status="$(container_status "catapult" "brats")"
kubectl delete pod -n catapult brats
exit "$status"
