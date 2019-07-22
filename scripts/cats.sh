#!/bin/bash

set -ex 

. scripts/include/common.sh

[ ! -d "cf-acceptance-tests" ] && git clone https://github.com/cloudfoundry/cf-acceptance-tests

pushd cf-acceptance-tests
cat > config.json <<EOF
{
  "api"                             : "api.${container_ip}.nip.io",
  "apps_domain"                     : "${container_ip}.nip.io",
  "admin_user": "admin",
  "admin_password": "password",
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

export GOPATH=$PWD/go 
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN
#go get -d github.com/cloudfoundry/cf-acceptance-tests
./bin/update_submodules

mkdir -p $GOPATH/src/github.com/cloudfoundry
[ ! -e "$GOPATH/src/github.com/cloudfoundry/cf-acceptance-tests" ] && ln -s $PWD $GOPATH/src/github.com/cloudfoundry/cf-acceptance-tests
pushd $GOPATH/src/github.com/cloudfoundry/cf-acceptance-tests

CONFIG=$PWD/config.json ./bin/test