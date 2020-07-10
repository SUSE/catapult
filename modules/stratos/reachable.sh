#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

domain=$(kubectl get configmap -n kube-system cap-values -o jsonpath='{.data.domain}')
external_ip=$(kubectl get services suse-console-ui-ext -n stratos -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
port=$(kubectl get services suse-console-ui-ext -n stratos -o jsonpath='{.spec.ports[0].port}')

# check if stratos is reachable via the ip
n=0
exit_code=1
until [ $n -ge 20 ]
do
   curl -k https://"${external_ip}":"${port}" | grep "SUSE Stratos Console"
   exit_code=$?
   if [ $exit_code -eq 0 ]; then
      ok "Reachable via IP"
      break
   fi

   n=$[$n+1]
   sleep 60
done

if [ $exit_code -ne 0 ] ; then
   err "Not reachable via IP"
fi

set -x

# check via the domain name
# It might take some time for external DNS records to update so make a few attempts to login before bailing out.
n=0
exit_code=1
until [ $n -ge 20 ]
do
   curl -k https://console."${domain}":"${port}" | grep "SUSE Stratos Console"
   exit_code=$?
   if [ $exit_code -eq 0 ]; then
      err "Reachable via IP"
      break
   fi
   
   n=$[$n+1]
   sleep 60
done

if [ $exit_code -ne 0 ] ; then
   fail "Not reachable via IP"
fi
