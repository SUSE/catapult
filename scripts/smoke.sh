#!/bin/bash

set -ex 
pushd build
export KUBECONFIG=kubeconfig
cluster_name=$(./kind get clusters)
container_id=$(docker ps -f "name=${cluster_name}-control-plane" -q)
container_ip=$(docker inspect $container_id | jq -r .[0].NetworkSettings.Networks.bridge.IPAddress)

git clone https://github.com/cloudfoundry/cf-smoke-tests

pushd cf-smoke-tests
cat > config.json <<EOF
{
  "suite_name"                      : "CF_SMOKE_TESTS",
  "skip_ssl_validation": true,
  "api"                             : "api.${container_ip}.nip.io",
  "apps_domain"                     : "${container_ip}.nip.io",
  "user"                            : "admin",
  "password"                        : "password",
  "cleanup"                         : false,
  "logging_app"                     : "",
  "runtime_app"                     : "",
  "enable_windows_tests"            : false,
  "windows_stack"                   : "windows2012R2",
  "isolation_segment_name"          : "is1",
  "isolation_segment_domain"        : "is1.bosh-lite.com",
  "enable_isolation_segment_tests"  : false
}
EOF

GOPATH=$PWD/go 
GOBIN=$GOPATH/bin
PATH=$PATH:$GOBIN

mkdir -p $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests
ln -s $PWD/ $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests
pushd $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests

go get github.com/onsi/gomega
go get github.com/cloudfoundry-incubator/cf-test-helpers

CONFIG=$PWD/config.json ./bin/test