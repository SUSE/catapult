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
  assertContains 'generates correctly GARDEN_ROOTFS_DRIVER' "$VALUES_FILE" "GARDEN_ROOTFS_DRIVER: \"btrfs\""
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
  rm -rf buildtest
  BACKEND=gke make buildir
  assertTrue 'create buildir' "[ -d 'buildtest' ]"
  ENVRC="$(cat "$PWD"/buildtest/.envrc)"
  assertContains 'contains BACKEND' "$ENVRC" 'BACKEND=gke'
  BACKEND=gke make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
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
  CONFIG=$PWD/test.json make buildir
  assertTrue 'create buildir' "[ -d 'buildjson' ]"
  ENVRC="$(cat "$PWD"/buildjson/.envrc)"
  assertContains 'contains BACKEND' "$ENVRC" 'BACKEND=gke'
  assertContains 'contains CLUSTER_NAME' "$ENVRC" 'CLUSTER_NAME=json'
  CONFIG=$PWD/test.json make clean
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

testscfChart() {
  rm -rf buildtest
  DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
  assertTrue 'yq was not downloaded' "[ ! -e 'buildtest/bin/yq' ]"
  assertTrue 'chart downloaded from URL (chart is present)' "[ -e 'buildtest/chart' ]"
  assertTrue 'chart was not generated' '[ -z "$(ls buildtest/*.tgz buildtest/*.zip)" ]'
  assertTrue 'chart downloaded (scf_chart_url is present)' "[ -e 'buildtest/scf_chart_url' ]"
  assertTrue 'chart downloaded from an http resource (scf_chart_url contains http)' "grep 'http' 'buildtest/scf_chart_url'"

  SCF_HELM_VERSION="2.14.5" DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
  assertTrue 'yq was downloaded' "[ -e 'buildtest/bin/yq' ]"
  assertTrue 'chart was generated (tgz present)' "[ -e 'buildtest/scf-sle-2.14.5+cf2.7.0.0.g6360c016.tgz' ]"
  assertTrue 'chart was generated (zip present)' "[ -e 'buildtest/scf-sle-2.14.5+cf2.7.0.0.g6360c016.zip' ]"
  assertTrue 'chart not downloaded' "[ ! -e 'buildtest/scf_chart_url' ]"

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"

  SCF_CHART="https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" DEFAULT_STACK=sle15 CLUSTER_PASSWORD=test123 make buildir scf-chart scf-gen-config
  assertTrue 'yq was not downloaded' "[ ! -e 'buildtest/bin/yq' ]"
  assertTrue 'chart downloaded from URL (chart is present)' "[ -e 'buildtest/chart' ]"
  assertTrue 'chart was not generated' '[ -z "$(ls buildtest/*.tgz buildtest/*.zip)" ]'
  assertTrue 'chart downloaded (scf_chart_url is present)' "[ -e 'buildtest/scf_chart_url' ]"
  assertTrue 'chart downloaded from an http resource (scf_chart_url contains http)' "grep 'http' 'buildtest/scf_chart_url'"
  assertTrue 'chart downloaded from an http resource matches' '[[ "https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" == "$(cat buildtest/scf_chart_url)" ]]'

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

testCommonDeps() {
  rm -rf buildtest
  make buildir
  make private modules/common

  assertTrue 'helm downloaded' "[ -e 'buildtest/bin/helm' ]"
  assertTrue 'tiller downloaded' "[ -e 'buildtest/bin/tiller' ]"

  make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Load shUnit2.
. ./shunit2/shunit2
