#!/usr/bin/env bash

if [[ $(yq r scf-config-values.yaml features.autoscaler.enabled) == "true" ]]; then
    for pod in $(kubectl get pods -n scf --output=jsonpath={.items..metadata.name} | \
                     grep -E --only-matching 'asactors-[0-9]*|asapi-[0-9]*');
    do
        if kubectl get pods -n scf $pod | grep -qi CrashLoopBackOff; then
            info "Applying WORKAROUND $(basename ${BASH_SOURCE[0]})"
            set +x # print workaround
            kubectl delete pod $pod --namespace scf
            debug_mode # reset printing option
        fi
    done
fi
