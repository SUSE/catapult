#!/bin/bash

set -ex

. scripts/include/common.sh
. .envrc

DOMAIN=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')

[ ! -d "cf-smoke-tests" ] && git clone https://github.com/cloudfoundry/cf-smoke-tests

if [ "${SCF_OPERATOR}" == "true" ]; then
    CLUSTER_PASSWORD=$(kubectl get secret -n scf scf.var-cf-admin-password -o json | jq -r .data.password | base64 -d)
fi

pushd cf-smoke-tests
cat > config.json <<EOF
{
  "suite_name"                      : "CF_SMOKE_TESTS",
  "skip_ssl_validation": true,
  "api"                             : "api.${DOMAIN}",
  "apps_domain"                     : "${DOMAIN}",
  "user"                            : "admin",
  "password"                        : "${CLUSTER_PASSWORD}",
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

export GOPATH="$PWD"/go
export GOBIN="$GOPATH"/bin
export PATH="$PATH":"$GOBIN"
go get github.com/onsi/ginkgo/ginkgo
go install github.com/onsi/ginkgo/ginkgo
rm -rf "$GOPATH"/src/*

mkdir -p "$GOPATH"/src/github.com/cloudfoundry
[ ! -e "$GOPATH"/src/github.com/cloudfoundry/cf-smoke-tests ] && ln -s "$PWD" "$GOPATH"/src/github.com/cloudfoundry/cf-smoke-tests
pushd "$GOPATH"/src/github.com/cloudfoundry/cf-smoke-tests


if [ -n "$EKCP_PROXY" ]; then
    export https_proxy=socks5://127.0.0.1:2224
fi

CONFIG="$PWD"/config.json ./bin/test
