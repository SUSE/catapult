#!/bin/bash

ROOT_DIR="$(git rev-parse --show-toplevel)"
export CLUSTER_NAME=test
export BACKEND=kind
export ENABLE_EIRINI=false

[ ! -d "shunit2" ] && git clone https://github.com/kward/shunit2.git

setUp() {
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    export ROOT_DIR
    pushd "$ROOT_DIR" || exit
}

tearDown() {
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    export ROOT_DIR
    pushd "$ROOT_DIR" || exit
    rm -rf buildtest
}

# # Tests creation and deletion of build directory
# testDeployment() {
#   rm -rf buildtest
#   make scf-deploy
#   deployst=$?
#   pushd buildtest || exit
#   source .envrc
#   popd || exit
#   assertTrue 'create buildir' "[ -d 'buildtest' ]"
#   PODS="$(kubectl get pods -n scf)"
#   SVCS="$(kubectl get svc -n scf)"
#   assertContains 'contains scf-cc-worker-v1 pod' "$PODS" 'scf-cc-worker-v1'
#   assertContains 'contains cf-operator-webhook svc' "$SVCS" 'cf-operator-webhook'
#   assertContains 'contains scf-api svc' "$SVCS" 'scf-api'
#   assertTrue 'deploys successfully' "[ \"$deployst\" == \"0\"]"
#   make tests-smoke-kube
#   kubert=$?
#   assertTrue 'smoke pass successfully' "[ \"$kubert\" == \"0\"]"
#   make clean
#   assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
# }

testKind() {
    rm -rf buildtest
    BACKEND=kind make k8s
    deployst=$?
    echo "DEPLOYS: $deployst"
    assertTrue 'create buildir' "[ -d 'buildtest' ]"
    assertEquals 'deploys successfully' "$deployst" "0"
    make scf-chart
    assertTrue 'helm folder is present' "[ -d 'buildtest/helm' ]"
    AUTOSCALER=true make scf-gen-config
    VALUES_FILE=$(cat $ROOT_DIR/buildtest/scf-config-values.yaml)
    assertContains 'generates correctly AUTOSCALER' "$VALUES_FILE" "autoscaler: true"
    make module-extra-ingress
    deployst=$?
    assertEquals 'deploys ingress successfully' "$deployst" "0"
    echo "#!/bin/bash" > buildtest/test.sh
    echo "set -ex" >> buildtest/test.sh
    echo "echo 'test'" >> buildtest/test.sh
    chmod +x buildtest/test.sh
    TASK_SCRIPT="$PWD/buildtest/test.sh" make module-extra-task
    taskst=$?
    assertEquals 'Executes task successfully' "$taskst" "0"
    make clean
    assertTrue 'clean buildir' "[ ! -d 'buildtest' ]"
}

# Load shUnit2.
. ./shunit2/shunit2
