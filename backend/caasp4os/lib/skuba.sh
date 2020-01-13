#!/usr/bin/env bash

# Functions to interact with a container that includes the client caasp4
# binaries and terraform

SKUBA_CLUSTER_NAME="my-cluster" #default from caasp

_set_env_vars() {
    JSON=$(skuba_container terraform output -json)
    export LB="$(echo "$JSON" | jq -r '.ip_load_balancer.value')"
    export MASTERS="$(echo "$JSON" | jq -r '.ip_masters.value|@tsv')"
    export WORKERS="$(echo "$JSON" | jq -r '.ip_workers.value|@tsv')"
    export ALL="$MASTERS $WORKERS"
}

_define_node_group() {
    _set_env_vars
    case "$1" in
        "all")
            GROUP="$ALL"
            ;;
        "masters")
            GROUP="$MASTERS"
            ;;
        "workers")
            GROUP="$WORKERS"
            ;;
        *)
            GROUP="$1"
            ;;
    esac
}

DEBUG_MODE=${DEBUG_MODE:-false}
if [ DEBUG_MODE = true ]; then
    DEBUG=1
else
    DEBUG=0
fi

skuba_container() {
    # Usage:
    # skuba_container <commands to run in a punctured container>

    local app_path="$PWD"
    if [[ "$1" == "$SKUBA_CLUSTER_NAME" ]]; then
        local app_path="$PWD/$1"
        shift
    fi
    docker run -i --rm \
    -v "$app_path":/app:rw \
    -v "$(dirname "$SSH_AUTH_SOCK")":"$(dirname "$SSH_AUTH_SOCK")" \
    -v "/etc/passwd:/etc/passwd:ro" \
    --env-file <( env| cut -f1 -d= ) \
    -e SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
    -u "$(id -u)":"$(id -g)" \
    skuba/$CAASP_VER "$@"
}

_ssh2() {
    local host=$1
    shift
    ssh -o UserKnownHostsFile=/dev/null \
        -o StrictHostKeyChecking=no \
        -F /dev/null \
        -o LogLevel=ERROR \
        "sles@$host" "$@"
}

skuba_wait_ssh() {
    # Usage:
    # wait_ssh <target>

    timeout=$2
    local target="${1:-all}"

    _define_node_group "$target"
    for n in $GROUP; do
        secs=0
        set +e
        _ssh2 $n exit
        while test $? -gt 0
        do
            if [ $secs -gt $timeout ] ; then
                echo "Timeout while waiting for $n"
                exit 2
            else
                sleep 5
                secs=$(( secs + 5 ))
                _ssh2 $n exit
            fi
        done
        set -e
    done
}

skuba_reboots() {
    # usage:
    # reboots disable

    local action="${1:-disable}"

    if [[ "$action" == "disable" ]]; then
        kubectl -n kube-system annotate ds kured weave.works/kured-node-lock='{"nodeid":"manual"}'
    else
        kubectl -n kube-system annotate ds kured weave.works/kured-node-lock-
    fi
}

skuba_run_cmd() {
    # Usage:
    # run_cmd <target> "sudo ..."
    # run_cmd all "sudo ..."
    # run_cmd masters "sudo ..."

    local target="${1:-all}"

    _define_node_group "$target"
    for n in $GROUP; do
        _ssh2 "$n" "$@"
    done
}

skuba_use_scp() {
    # Usage:
    # use_scp <target> <src_files> <dest_files>
    # use_scp masters <src_files> <dest_files>
    # use_scp workers <src_files> <dest_files>

    local target="${1:-all}"

    _define_node_group "$target"
    SRC="$2"
    DEST="$3"
    local options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -F /dev/null -o LogLevel=ERROR -r"

    for n in $GROUP; do
        scp "$options" "$SRC" sles@$n:"$DEST"
    done
}

skuba_show_images() {
    kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n'
}

skuba_updates() {
    # Usage:
    # updates <target> <action>
    # updates all disable

    local target="${1:-all}"
    local action="${2:-disable}"

    _define_node_group "$target"
    for n in $GROUP; do
        _ssh2 "$n" "sudo systemctl $action --now skuba-update.timer"
    done
}

_init_control_plane() {
    if ! [[ -d "$SKUBA_CLUSTER_NAME" ]]; then
        skuba_container skuba cluster init --control-plane "$LB" "$SKUBA_CLUSTER_NAME"
    fi
}

_deploy_masters() {
local i=0
for n in $1; do
    local j="$(printf "%03g" $i)"
    if [[ $i -eq 0 ]]; then
      skuba_container "$SKUBA_CLUSTER_NAME" skuba node bootstrap --user sles --sudo --target "$n" "master$j" -v "$DEBUG"
      wait
    fi

    if [[ $i -ne 0 ]]; then
      skuba_container "$SKUBA_CLUSTER_NAME" skuba node join --role master --user sles --sudo --target  "$n" "master$j" -v "$DEBUG"
      wait
    fi
    ((++i))
done
}

_deploy_workers() {
    local i=0
    for n in $1; do
        local j="$(printf "%03g" $i)"
        (skuba_container "$SKUBA_CLUSTER_NAME" skuba node join --role worker --user sles --sudo --target  "$n" "worker$j" -v "$DEBUG") &
        wait
        ((++i))
    done
}

skuba_deploy() {
    # Usage: deploy

    local KUBECONFIG=""
    _set_env_vars
    _init_control_plane
    pushd $(pwd)/
    _deploy_masters "$MASTERS"
    _deploy_workers "$WORKERS"
    skuba_container $SKUBA_CLUSTER_NAME skuba cluster status
}

skuba_node_upgrade() {
    # Usage:
    #   skuba_node_upgrade <target>
    #   skuba_node_upgrade all
    #   skuba_node_upgrade masters
    #   skuba_node_upgrade workers

    local target="${1:-all}"

     _define_node_group "$target"
    local i=0
    for n in $GROUP; do
        skuba_container "$SKUBA_CLUSTER_NAME" skuba node upgrade \
                        apply --user sles --sudo --target "$n" -v "$DEBUG"
    done
}
