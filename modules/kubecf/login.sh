#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc


if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:${KUBEPROXY_PORT}
fi

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
admin_pass=$(kubectl get secret --namespace scf \
                     var-cf-admin-password \
                     -o jsonpath='{.data.password}' | base64 --decode)

mkdir -p "$CF_HOME"

# It might take some time for external DNS records to update so make a few attempts to login before bailing out.
n=0
until [ $n -ge 20 ]
do
   set +e
   cf login --skip-ssl-validation -a https://api."$domain" -u admin -p "$admin_pass" -o system
   exit_code=$?
   set -e
   if [ $exit_code -eq 0 ]; then

      cf create-space tmp
      cf target -s tmp

      ok "Logged in to KubeCF"
      break
   fi

   n=$[$n+1]
   sleep 60
done

if [ $exit_code -ne 0 ] ; then
   err "Could not log into KubeCF"
   exit $exit_code
fi
