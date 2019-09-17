#!/bin/bash

set -ex

. scripts/include/common.sh
. .envrc

DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

if [ -z "${DEFAULT_STACK}" ]; then
    export DEFAULT_STACK=$(helm inspect helm/cf/ | grep DEFAULT_STACK | sed  's~DEFAULT_STACK:~~g' | sed 's~"~~g' | sed 's~\s~~g')
fi

if [ "${SCF_OPERATOR}" == "true" ]; then
    CLUSTER_PASSWORD=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -d)
fi

[ ! -d "cf-acceptance-tests" ] && git clone https://github.com/cloudfoundry/cf-acceptance-tests

pushd cf-acceptance-tests
cat > config.json <<EOF
{
  "api"                             : "api.${DOMAIN}",
  "apps_domain"                     : "${DOMAIN}",
  "admin_user": "admin",
  "admin_password": "${CLUSTER_PASSWORD}",
  "artifacts_directory": "logs",
  "skip_ssl_validation": true,
  "timeout_scale": 1,
  "use_http": true,
  "use_log_cache": false,
  "include_apps": true,
  "include_backend_compatibility": true,
  "include_capi_experimental": false,
  "include_capi_no_bridge": true,
  "include_container_networking": true,
  "credhub_mode" : "assisted",
  "credhub_client": "credhub_admin_client",
  "credhub_secret": "credhub_secret",
  "include_detect": true,
  "include_docker": true,
  "include_internet_dependent": true,
  "include_internetless": false,
  "include_isolation_segments": false,
  "include_logging_isolation_segments": false,
  "include_private_docker_registry": false,
  "include_route_services": true,
  "include_routing": true,
  "include_tcp_routing": true,
  "include_routing_isolation_segments": false,
  "include_security_groups": true,
  "include_service_discovery": false,
  "include_services": true,
  "include_service_instance_sharing": true,
  "include_ssh": true,
  "include_sso": true,
  "include_tasks": true,
  "include_v3": true,
  "include_zipkin": true,
  "include_credhub": false,
  "include_tcp_routing": true,
  "include_volume_services": false,
  "stacks": [
    "${DEFAULT_STACK}"
  ]
}
EOF

export GOPATH="$PWD"/go
export GOBIN="$GOPATH"/bin
export PATH="$PATH":"$GOBIN"
go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo
rm -rf "$GOPATH"/src/*

#go get -d github.com/cloudfoundry/cf-acceptance-tests
./bin/update_submodules

mkdir -p "$GOPATH"/src/github.com/cloudfoundry
[ ! -e "$GOPATH"/src/github.com/cloudfoundry/cf-acceptance-tests ] && ln -s "$PWD" "$GOPATH"/src/github.com/cloudfoundry/cf-acceptance-tests
pushd "$GOPATH"/src/github.com/cloudfoundry/cf-acceptance-tests
go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo
if [ -n "$EKCP_PROXY" ]; then
  export https_proxy=socks5://127.0.0.1:2224
fi
CONFIG="$PWD"/config.json ./bin/test
