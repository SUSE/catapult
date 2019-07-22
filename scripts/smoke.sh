#!/bin/bash

set -ex 

. scripts/include/common.sh

[ ! -d "cf-smoke-tests" ] && git clone https://github.com/cloudfoundry/cf-smoke-tests

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

export GOPATH=$PWD/go 
export GOBIN=$GOPATH/bin
export PATH=$PATH:$GOBIN

mkdir -p $GOPATH/src/github.com/cloudfoundry
ln -s $PWD $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests
pushd $GOPATH/src/github.com/cloudfoundry/cf-smoke-tests

CONFIG=$PWD/config.json ./bin/test