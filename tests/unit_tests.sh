#!/bin/bash

ROOT_DIR="$(git rev-parse --show-toplevel)"

[ ! -d "shunit2" ] && git clone https://github.com/kward/shunit2.git

setUp() {
    export PATH=$ROOT_DIR/tests/mocks:"$PATH"
    export CLUSTER_NAME=test
    export ROOT_DIR="$(git rev-parse --show-toplevel)"
    pushd "$ROOT_DIR"
}

tearDown() {
    export ROOT_DIR="$(git rev-parse --show-toplevel)"
    pushd "$ROOT_DIR"
    rm -rf buildtest
}

# Tests creation and deletion of build directory
testBuilddir() {
  rm -rf buildtest
  make buildir
  assertTrue 'create buildir' "[ -d 'buildtest' ]"
  ENVRC="$(cat "$PWD"/buildtest/.envrc)"
  assertContains 'contains KUBECONFIG' "$ENVRC" "KUBECONFIG=\"$PWD/buildtest\"/kubeconfig"
  assertContains 'contains CLUSTER_NAME' "$ENVRC" 'CLUSTER_NAME=test'
  assertContains 'contains BACKEND kind (default)' "$ENVRC" 'BACKEND=kind'
  assertContains 'contains CF_HOME' "$ENVRC" "CF_HOME=\"$PWD/buildtest\""
  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Tests values generation
testConfig() {
  rm -rf buildtest
  make buildir
  DEFAULT_STACK=sle CLUSTER_PASSWORD=test123 STORAGECLASS=our-storage make scf-gen-config
  assertTrue 'create buildir' "[ -d $ROOT_DIR/buildtest ]"
  assertTrue 'create config values' "[ -e $ROOT_DIR/buildtest/scf-config-values.yaml ]"

  VALUES_FILE="$(cat $ROOT_DIR/buildtest/scf-config-values.yaml)"
  assertContains 'generates correctly CLUSTER_ADMIN_PASSWORD' "$VALUES_FILE" "CLUSTER_ADMIN_PASSWORD: test123"
  assertContains 'generates correctly KUBE_CSR_AUTO_APPROVAL' "$VALUES_FILE" "KUBE_CSR_AUTO_APPROVAL: true"
  assertContains 'generates correctly DEFAULT_STACK' "$VALUES_FILE" "DEFAULT_STACK: \"sle\""
  assertContains 'generates correctly GARDEN_ROOTFS_DRIVER' "$VALUES_FILE" "GARDEN_ROOTFS_DRIVER: \"overlay-xfs\""
  assertContains 'generates correctly STORAGECLASS (1)' "$VALUES_FILE" "kube_storage_class: \"our-storage\""
  assertContains 'generates correctly STORAGECLASS (2)' "$VALUES_FILE" "persistent: \"our-storage\""
  assertContains 'generates correctly STORAGECLASS (3)' "$VALUES_FILE" "shared: \"our-storage\""
  assertContains 'generates correctly AUTOSCALER' "$VALUES_FILE" "autoscaler: false"

  AUTOSCALER=true make scf-gen-config
  VALUES_FILE="$(cat $ROOT_DIR/buildtest/scf-config-values.yaml)"
  assertContains 'generates correctly AUTOSCALER' "$VALUES_FILE" "autoscaler: true"
}

# Tests backend switch
testBackend() {
    for b in kind caasp4os eks gke imported minikube; do
        if [ -d "$ROOT_DIR/backend/$b" ]; then
            rm -rf buildtest
            BACKEND="$b" make buildir
            assertTrue 'create buildir' "[ -d 'buildtest' ]"
            ENVRC="$(cat "$PWD"/buildtest/.envrc)"
            assertContains 'contains BACKEND' "$ENVRC" BACKEND="$b"
            BACKEND="$b" make clean
            assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
        fi
    done
}

# Tests imported backend
testBackendImported() {
    rm -rf buildtest
    BACKEND=imported make buildir
    assertTrue 'create buildir' "[ -d 'buildtest' ]"
    ENVRC="$(cat "$PWD"/buildtest/.envrc)"
    assertContains 'contains BACKEND' "$ENVRC" 'BACKEND=imported'
    echo "foo" > buildtest/kubeconfig_orig
    KUBECFG=$(pwd)/buildtest/kubeconfig_orig \
              BACKEND=imported \
              make kubeconfig
    assertTrue 'imported kubeconfig' 'diff "$PWD"/buildtest/kubeconfig "$PWD"/buildtest/kubeconfig_orig'
    assertFalse "BACKEND=imported make check must fail" 'BACKEND=imported make private backends/imported check'
    BACKEND=imported make clean
    assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Tests Json config switch
testJson() {
  unset CLUSTER_NAME
  unset BACKEND
  rm -rf buildjson
  echo '{ "BACKEND": "gke", "CLUSTER_NAME": "json" }' > test.json
  BACKEND=gke CONFIG=$PWD/test.json make buildir
  assertTrue 'create buildir' "[ -d 'buildjson' ]"
  ENVRC="$(cat "$PWD"/buildjson/.envrc)"
  assertContains 'contains BACKEND' "$ENVRC" 'BACKEND=gke'
  assertContains 'contains CLUSTER_NAME' "$ENVRC" 'CLUSTER_NAME=json'
  BACKEND=gke CONFIG=$PWD/test.json make clean
  assertTrue 'clean buildir' "[ ! -d 'buildjson' ]"
  rm -rf test.json
}

testJsonOverrides() {
  unset CLUSTER_NAME
  unset BACKEND
  rm -rf buildjson
  echo '{ "BACKEND": "gke", "CLUSTER_NAME": "json" }' > test.json
  BACKEND=imported CONFIG=$PWD/test.json make buildir
  assertTrue 'create buildir' "[ -d 'buildjson' ]"
  ENVRC="$(cat "$PWD"/buildjson/.envrc)"
  assertContains 'contains BACKEND' "$ENVRC" 'BACKEND=imported'
  assertContains 'contains CLUSTER_NAME' "$ENVRC" 'CLUSTER_NAME=json'
  BACKEND=imported CONFIG=$PWD/test.json make clean
  assertTrue 'clean buildir' "[ ! -d 'buildjson' ]"
  rm -rf test.json
}

# testscfChart() {
#   rm -rf buildtest
#   DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
#   assertTrue 'yq was not downloaded' "[ ! -e 'buildtest/bin/yq' ]"
#   assertTrue 'chart downloaded from URL (chart is present)' "[ -e 'buildtest/chart' ]"
#   assertTrue 'chart was not generated' '[ -z "$(ls buildtest/*.tgz buildtest/*.zip)" ]'
#   assertTrue 'chart downloaded (scf_chart_url is present)' "[ -e 'buildtest/scf_chart_url' ]"
#   assertTrue 'chart downloaded from an http resource (scf_chart_url contains http)' "grep 'http' 'buildtest/scf_chart_url'"

#   SCF_HELM_VERSION="2.14.5" DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
#   assertTrue 'yq was downloaded' "[ -e 'buildtest/bin/yq' ]"
#   assertTrue 'chart was generated (tgz present)' "[ -e 'buildtest/scf-sle-2.14.5+cf2.7.0.0.g6360c016.tgz' ]"
#   assertTrue 'chart was generated (zip present)' "[ -e 'buildtest/scf-sle-2.14.5+cf2.7.0.0.g6360c016.zip' ]"
#   assertTrue 'chart not downloaded' "[ ! -e 'buildtest/scf_chart_url' ]"

#   make clean
#   assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"

#   SCF_CHART="https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
#   assertTrue 'yq was not downloaded' "[ ! -e 'buildtest/bin/yq' ]"
#   assertTrue 'chart downloaded from URL (chart is present)' "[ -e 'buildtest/chart' ]"
#   assertTrue 'chart was not generated' '[ -z "$(ls buildtest/*.tgz buildtest/*.zip)" ]'
#   assertTrue 'chart downloaded (scf_chart_url is present)' "[ -e 'buildtest/scf_chart_url' ]"
#   assertTrue 'chart downloaded from an http resource (scf_chart_url contains http)' "grep 'http' 'buildtest/scf_chart_url'"
#   assertTrue 'chart downloaded from an http resource matches' '[[ "https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" == "$(cat buildtest/scf_chart_url)" ]]'

#   make clean
#   assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
# }

testCommonDeps() {
  rm -rf buildtest
  make buildir
  DOWNLOAD_BINS=false DOWNLOAD_CATAPULT_DEPS=false make private modules/common

  assertFalse 'helm not downloaded' "[ -e 'buildtest/bin/helm' ]"
  assertFalse 'tiller not downloaded' "[ -e 'buildtest/bin/tiller' ]"
  assertFalse 'kubectl not downloaded' "[ -e 'buildtest/bin/kubectl' ]"
  assertFalse 'cfcli not downloaded' "[ -e 'buildtest/bin/cf' ]"

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"

  make buildir
  DOWNLOAD_CATAPULT_DEPS=false make private modules/common

  assertTrue 'helm downloaded' "[ -e 'buildtest/bin/helm' ]"
  assertTrue 'tiller downloaded' "[ -e 'buildtest/bin/tiller' ]"
  assertTrue 'kubectl downloaded' "[ -e 'buildtest/bin/kubectl' ]"
  assertTrue 'cfcli downloaded' "[ -e 'buildtest/bin/cf' ]"

  DOWNLOADED_KUBECTLVER=$(./buildtest/bin/kubectl version -o json --client=true | jq -r '.clientVersion.gitVersion')
  . "$ROOT_DIR"/backend/kind/defaults.sh # load expected $KUBECTL_VERSION
  assertEquals 'kubectl versions match' "$DOWNLOADED_KUBECTLVER" "$KUBECTL_VERSION"

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"

  make buildir
  DOWNLOAD_BINS=false DOWNLOAD_CATAPULT_DEPS=false make private modules/common

  assertFalse 'bazel not downloaded' "[ -e 'buildtest/bin/bazel' ]"
  assertFalse 'yaml-patch not downloaded' "[ -e 'buildtest/bin/yaml-patch' ]"
  assertFalse 'yq not downloaded' "[ -e 'buildtest/bin/yq' ]"

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"

  make buildir
  DOWNLOAD_BINS=false make private modules/common

  assertTrue 'bazel downloaded' "[ -e 'buildtest/bin/bazel' ]"
  assertTrue 'yaml-patch downloaded' "[ -e 'buildtest/bin/yaml-patch' ]"
  assertTrue 'yq downloaded' "[ -e 'buildtest/bin/yq' ]"
}

# Load shUnit2.
. ./shunit2/shunit2
