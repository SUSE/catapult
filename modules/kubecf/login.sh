#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

mkdir -p "$CF_HOME"

# It might take some time for external DNS records to update so make a few attempts to login before bailing out.
n=0
until [ $n -ge 20 ]
do
   cf login --skip-ssl-validation -a https://api."$domain" -u admin -p "$CLUSTER_PASSWORD" -o system && break
   n=$[$n+1]
   sleep 60
done

cf create-space tmp
cf target -s tmp

ok "Logged in to SCF"
