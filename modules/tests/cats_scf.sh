#!/bin/bash

. ../../include/common.sh
. .envrc


DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
generated_secrets_secret="$(kubectl get pod api-group-0 -n scf -o jsonpath='{@.spec.containers[0].env[?(@.name=="MONIT_PASSWORD")].valueFrom.secretKeyRef.name}')"
SCF_LOG_HOST=$(kubectl get pods -o json -n scf api-group-0 | jq -r '.spec.containers[0].env[] | select(.name == "SCF_LOG_HOST").value')

kube_overrides() {
    # overrides of acceptance-tests.yaml
    ruby <<EOF
        require 'yaml'
        require 'json'

        obj = YAML.load_file('kube/cf/bosh-task/acceptance-tests.yaml')
        obj['spec']['containers'].each do |container|
            container['env'].each do |env|
                env['value'] = '$DOMAIN'     if env['name'] == 'DOMAIN'
                env['value'] = 'tcp.$DOMAIN' if env['name'] == 'TCP_DOMAIN'
                env['value'] = '$SCF_LOG_HOST' if env['name'] == 'SCF_LOG_HOST'
                if env['name'] == "MONIT_PASSWORD"
                    env['valueFrom']['secretKeyRef']['name'] = '$generated_secrets_secret'
                end
                if env['name'] == "UAA_CLIENTS_CF_SMOKE_TESTS_CLIENT_SECRET"
                    env['valueFrom']['secretKeyRef']['name'] = '$generated_secrets_secret'
                end
                if env['name'] == "AUTOSCALER_SERVICE_BROKER_PASSWORD"
                    env['valueFrom']['secretKeyRef']['name'] = '$generated_secrets_secret'
                end
            end
            container.delete "resources"
        end
        # Rename imagePullSecrets so it is specific to the tests images and
        # doesn't clash with any other imagePullSecrets after creating the
        # docker-registry k8s secret:
        obj['spec']['imagePullSecrets'] = ['name' => 'tests-registry-credentials']
        puts obj.to_json
EOF
}

if kubectl get secrets -n scf 2>/dev/null | grep -qi tests-registry-credentials; then
    kubectl delete secret tests-registry-credentials -n scf
fi
if kubectl get pods -n scf 2>/dev/null | grep -qi acceptance-tests; then
    kubectl delete pod acceptance-tests -n scf
fi

SECRETS_FILE=${SECRETS_FILE:-"$ROOT_DIR"/../cloudfoundry/secure/concourse-secrets.yml.gpg}
# Create secret for the imagePullSecrets we renamed in the scf images:
kubectl create secret docker-registry tests-registry-credentials \
        --namespace scf \
        --docker-server=$(grep "docker-internal-registry:" <<< $(gpg --decrypt --batch "$SECRETS_FILE") | cut -d ' ' -f 3- ) \
        --docker-username=$(grep "docker-internal-username:" <<< $(gpg --decrypt --batch "$SECRETS_FILE") | cut -d ' ' -f 3- ) \
        --docker-password="$(grep "docker-internal-password:" <<< $(gpg --decrypt --batch "$SECRETS_FILE") | cut -d ' ' -f 3- )"

image=$(gawk '$1 == "image:" { gsub(/"/, "", $2); print $2 }' kube/cf/bosh-task/acceptance-tests.yaml)
kubectl run \
        --namespace scf \
        --attach \
        --restart=Never \
        --image="$image" \
        --overrides="$(kube_overrides)" \
        "smoke-tests" ||:

wait_container_attached "scf" "acceptance-tests"

mkdir -p artifacts
kubectl logs -f acceptance-tests -n scf > artifacts/"$(date +'%H:%M-%Y-%m-%d')"_acceptance-tests.log

exit "$(container_status "scf" "acceptance-tests")"
