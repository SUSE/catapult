#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

# install the autoscaler cf cli plugin
cf add-plugin-repo "CF-Community" "https://plugins.cloudfoundry.org"
cf install-plugin -r CF-Community app-autoscaler-plugin -f

# clone sample app
SAMPLE_FOLDER=autoscaled-app
[ ! -d "$SAMPLE_FOLDER" ] && git clone --recurse-submodules "$SAMPLE_APP_REPO" "$SAMPLE_FOLDER"
pushd "$SAMPLE_FOLDER" || exit
if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

# push app without starting
cf push autoscaled-app --no-start

# bind the service instance to the app and attach policy
cat > autoscaler-policy.json <<EOF
{
    "instance_min_count": 1,
    "instance_max_count": 4,
    "scaling_rules": [{
                         "metric_type": "memoryused",
                         "stat_window_secs": 60,
                         "breach_duration_secs": 60,
                         "threshold": 10,
                         "operator": ">=",
                         "cool_down_secs": 300,
                         "adjustment": "+1"
                     }]
}
EOF
cf attach-autoscaling-policy autoscaled-app autoscaler-policy.json

# start app
cf start autoscaled-app
