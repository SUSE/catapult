#!/bin/bash

[ ! -d "shunit2" ] && git clone https://github.com/kward/shunit2.git

# Tests creation and deletion of build directory
testBuilddir() {
  CLUSTER_NAME=test make clean
  CLUSTER_NAME=test make buildir
  assertTrue 'create buildir' "[ -d 'buildtest' ]"
  ENVRC="$(cat $PWD/buildtest/.envrc)"
  assertContains 'contains KUBECONFIG' "$ENVRC" "KUBECONFIG=\"$PWD/buildtest\"/kubeconfig"
  assertContains 'contains CLUSTER_NAME' "$ENVRC" 'CLUSTER_NAME=test'
  assertContains 'contains CF_HOME' "$ENVRC" "CF_HOME=\"$PWD/buildtest\""
  CLUSTER_NAME=test make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Tests values generation
testConfig() {
  DEFAULT_STACK=sle CLUSTER_PASSWORD=test123 CLUSTER_NAME=test make buildir gen-config
  assertTrue 'create buildir' "[ -d 'buildtest' ]"
  assertTrue 'create config values' "[ -e 'buildtest/scf-config-values.yaml' ]"

  VALUES_FILE="$(cat buildtest/scf-config-values.yaml)"
  assertContains 'generates correctly CLUSTER_ADMIN_PASSWORD' "$VALUES_FILE" "CLUSTER_ADMIN_PASSWORD: test123"
  assertContains 'generates correctly KUBE_CSR_AUTO_APPROVAL' "$VALUES_FILE" "KUBE_CSR_AUTO_APPROVAL: true"
  assertContains 'generates correctly DEFAULT_STACK' "$VALUES_FILE" "DEFAULT_STACK: \"sle\""
  assertContains 'generates correctly GARDEN_ROOTFS_DRIVER' "$VALUES_FILE" "GARDEN_ROOTFS_DRIVER: \"btrfs\""

  CLUSTER_NAME=test make clean
  assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Load shUnit2.
. ./shunit2/shunit2