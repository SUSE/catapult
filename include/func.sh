#!/bin/bash

# Get defaults from binary dependencies
. $ROOT_DIR/modules/common/defaults.sh

set +x

if ((BASH_VERSINFO[0] >= 4)) && [[ $'\u2388 ' != "\\u2388 " ]]; then
        KUBE_IMG=$'\u2638 '
        ROCKET_IMG=$'\U1F680 '
        RECIPE_IMG=$'\U1F382 '
        ARROW_IMG=$'\U27A4 '
        INFO_IMG=$'\U2139 '
        WARN_IMG=$'\U26A0 '
        ERR_IMG=$'\U1F480 '
        OK_IMG=$'\U2705 '
    else
        KUBE_IMG=$'\xE2\x98\xB8 '
        ROCKET_IMG=$'\xF0\x9F\x9A\x80 '
        RECIPE_IMG=$'\xF0\x9F\x8E\x82 '
        ARROW_IMG=$'\xE2\x9E\xA4 '
        INFO_IMG=$'\xE2\x84\xB9 '
        WARN_IMG=$'\xE2\x9A\xA0 '
        ERR_IMG=$'\xF0\x9F\x92\x80 '
        OK_IMG=$'\xE2\x9C\x85 '
fi

#shellcheck disable=SC2034
{
# Reset
Color_Off='\033[0m'       # Text Reset
# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White

# Bold
BBlack='\033[1;30m'       # Black
BRed='\033[1;31m'         # Red
BGreen='\033[1;32m'       # Green
BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
BPurple='\033[1;35m'      # Purple
BCyan='\033[1;36m'        # Cyan
BWhite='\033[1;37m'       # White

# Underline
UBlack='\033[4;30m'       # Black
URed='\033[4;31m'         # Red
UGreen='\033[4;32m'       # Green
UYellow='\033[4;33m'      # Yellow
UBlue='\033[4;34m'        # Blue
UPurple='\033[4;35m'      # Purple
UCyan='\033[4;36m'        # Cyan
UWhite='\033[4;37m'       # White

# Background
On_Black='\033[40m'       # Black
On_Red='\033[41m'         # Red
On_Green='\033[42m'       # Green
On_Yellow='\033[43m'      # Yellow
On_Blue='\033[44m'        # Blue
On_Purple='\033[45m'      # Purple
On_Cyan='\033[46m'        # Cyan
On_White='\033[47m'       # White

# High Intensity
IBlack='\033[0;90m'       # Black
IRed='\033[0;91m'         # Red
IGreen='\033[0;92m'       # Green
IYellow='\033[0;93m'      # Yellow
IBlue='\033[0;94m'        # Blue
IPurple='\033[0;95m'      # Purple
ICyan='\033[0;96m'        # Cyan
IWhite='\033[0;97m'       # White

# Bold High Intensity
BIBlack='\033[1;90m'      # Black
BIRed='\033[1;91m'        # Red
BIGreen='\033[1;92m'      # Green
BIYellow='\033[1;93m'     # Yellow
BIBlue='\033[1;94m'       # Blue
BIPurple='\033[1;95m'     # Purple
BICyan='\033[1;96m'       # Cyan
BIWhite='\033[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\033[0;100m'   # Black
On_IRed='\033[0;101m'     # Red
On_IGreen='\033[0;102m'   # Green
On_IYellow='\033[0;103m'  # Yellow
On_IBlue='\033[0;104m'    # Blue
On_IPurple='\033[0;105m'  # Purple
On_ICyan='\033[0;106m'    # Cyan
On_IWhite='\033[0;107m'   # White
}

function simple {
    local cat="$2"
    local message="$1"
    # shellcheck disable=SC2153 #BACKEND comes from env
    echo "[$cat] [backend:$BACKEND] [cluster:${CLUSTER_NAME}] $message"
}

function info {
    set +x
    local message="$*"

    cat=$0

    if [ "${QUIET_OUTPUT}" == "true" ]; then
    simple "$message" "$cat"
    else
    printf "${BBlue}${INFO_IMG} ${BWhite}${ROCKET_IMG} ${On_Black}$BACKEND ${BPurple}${KUBE_IMG}${CLUSTER_NAME} ${IBlue} ${RECIPE_IMG} ${cat}${BBlue} ${ARROW_IMG} ${BWhite}${On_Black}$message$Color_Off\n"
    fi
    debug_mode
}

function ok {
    set +x
    local message="$*"

    cat=$0

    if [ "${QUIET_OUTPUT}" == "true" ]; then
    simple "$message" "$cat"
    else
    printf "${BGreen}${OK_IMG} ${BWhite}${ROCKET_IMG} ${On_Black}$BACKEND${IGreen} ${KUBE_IMG}${CLUSTER_NAME} ${RECIPE_IMG} ${cat}${BGreen} ${ARROW_IMG} ${BWhite}${On_Black}$message$Color_Off\n"
    fi
    debug_mode
}

function warn {
    set +x
    local message="$*"

    cat=$0

    if [ "${QUIET_OUTPUT}" == "true" ]; then
    simple "$message" "$cat"
    else
    printf "${BYellow}${WARN_IMG} ${BWhite}${ROCKET_IMG} ${On_Black}$BACKEND${IYellow} ${KUBE_IMG}${CLUSTER_NAME} ${RECIPE_IMG} ${cat}${BYellow} ${ARROW_IMG} ${BWhite}${On_Black}$message$Color_Off\n"
    fi
    debug_mode
}

function err {
    set +x
    local message="$*"

    cat=$0

    if [ "${QUIET_OUTPUT}" == "true" ]; then
    simple "$message" "$cat"
    else
    printf "${BRed}${ERR_IMG} ${BWhite}${ROCKET_IMG} ${On_Black}$BACKEND${IRed} ${KUBE_IMG}${CLUSTER_NAME} ${RECIPE_IMG} ${cat}${BRed} ${ARROW_IMG} ${BWhite}${On_Black}$message$Color_Off\n"
    fi
    debug_mode
}

function debug_mode {
    if [ -n "${DEBUG_MODE}" ] && [ "$DEBUG_MODE" == true ]; then
        set -x
    else
        set +x
    fi
}

function load_env_from_json {
    # Export but preserve one that are passed explictly
    eval "$(jq -r ' to_entries | .[] | "export "+ .key + "=\"${"+ .key + ":-" + .value + "}\""' < $1)"
}

function supported_backend {
    local backend=$1
    if [[ "$backend" != "$BACKEND" ]]; then
        err "Incompatible backend. Required backend $backend, while $BACKEND was provided."
        exit 1
    fi
}

function yamlpatch {
    # we cannot use stdin to pass the file that yaml-patch is going to edit, or the
    # file will change under its feet; use a temporal file
    OP_FILE="$1"
    PATCHED_FILE="$2"
    cp "$PATCHED_FILE"{,.bak}
    BAK_FILE="$PATCHED_FILE".bak
    cat "$BAK_FILE" | yaml-patch -o "$OP_FILE" > "$PATCHED_FILE"; rm "$OP_FILE" "$BAK_FILE"
}

function container_status {
    local NAMESPACE=$1
    local POD=$2

    kubectl get --output=json -n "$NAMESPACE" pod "$POD" \
        | jq '.status.containerStatuses[0].state.terminated.exitCode | tonumber' 2>/dev/null
}

function wait_container_attached {
    local NAMESPACE=$1
    local POD=$2

    while [[ -z $(container_status "$NAMESPACE" "$POD") ]]; do
        kubectl attach -n "$NAMESPACE" "$POD" -it 2>/dev/null ||:
    done
}

# wait_ns NAMESPACE MUSTHAVE MUSTNOT
# wait_ns waits for all pods in the NAMESPACE to be running or completed (and all containers to be running).
# It also waits until an instance of the MUSTHAVE pod exist (if non-blank), and that no instances of MUSTNOT
# exist (again, if non-blank). Only a single pod name is allowed for each of MUSTHAVE and MUSTNOT.
# See wait_for_kubecf() below for a usage example, and why all this is needed.
function wait_ns {
    local NAMESPACE=$1
    local MUSTHAVE=${2:-}
    local MUSTNOT=${3:-}

    while true; do
        local output
        if output="$(kubectl get pods --namespace "$NAMESPACE")"
        then
            if gawk <<< "${output}" '{ if ((match($2, /^([0-9]+)\/([0-9]+)$/, c) && c[1] != c[2] && !match($3, /Completed/)) || !match($3, /STATUS|Completed|Running/)) { print ; exit 1 } }'
            then
                local ready=1
                if [ -n "$MUSTHAVE" ]; then
                    if ! grep -q  <<< "${output}" -E "^${MUSTHAVE}-"; then
                        echo "Waiting for '$MUSTHAVE' pod"
                        ready=0
                    fi
                fi
                if [ -n "$MUSTNOT" ]; then
                    if grep -q  <<< "${output}" -E "^${MUSTNOT}-"; then
                        echo "Waiting for '$MUSTNOT' pod to go away"
                        grep <<< "${output}" -E "^${MUSTNOT}-"
                        ready=0
                    fi
                fi
                if [ $ready -eq 1 ]; then
                    echo "Ready:"
                    echo "${output}"
                    break
                fi
            fi
        fi
        sleep 10
    done
}

function helm_info {
    if [[ "$HELM_VERSION" == v3* ]]; then
        helm version --kubeconfig /dev/null
    else
        helm version --client
    fi
}

function helm_init {
    if [[ "$HELM_VERSION" != v3* ]]; then
        helm init --upgrade --wait
    else
        helm repo add stable https://charts.helm.sh/stable
        helm repo update
    fi
}

function helm_init_client {
    if [[ "$HELM_VERSION" != v3* ]]; then
        helm init --client-only
    else
        helm repo add stable https://charts.helm.sh/stable
        helm repo update
    fi
}

function helm_install {
    local release_name=$1;shift
    local chart=$1;shift
    if [[ "$HELM_VERSION" == v3* ]]; then
        helm install "$release_name" "$chart" "$@"
    else
        helm install --name "$release_name" "$chart" "$@"
    fi
}

function helm_upgrade {
    local release_name=$1;shift
    local chart=$1;shift
    if [[ "$HELM_VERSION" == v3* ]]; then
        # https://v3.helm.sh/docs/howto/charts_tips_and_tricks/#automatically-roll-deployments
        # we don't use recreate-pods anymore
        helm upgrade "$release_name" "$chart" "$@"
    else
        helm upgrade --name "$release_name" "$chart" --recreate-pods "$@"
    fi
}

function helm_delete {
    if [[ "$HELM_VERSION" == v3* ]]; then
        helm uninstall "$@"
        # wait until there's no helm release installed
        wait_for "! (helm ls --all-namespaces 2>/dev/null | grep -qi $1)"
    else
        helm delete --purge "$@"
    fi
}

function helm_ls {
    if [[ "$HELM_VERSION" == v3* ]]; then
        helm ls --all-namespaces
    else
        helm ls
    fi
}

# Given a chart path in $1, find its app version
function helm_chart_app_version {
    # helm 3 aliases "inspect" to "show", so the syntax is the same for 2 & 3.
    helm inspect chart "${1}" | yq read - version
}

function wait_for {
    info "Waiting for $1"
    timeout=300
    n=0; until ((n >= timeout)); do eval "$1" && break; n=$((n + 1)); sleep 1; done; ((n < timeout))
}

external_dns_annotate_uaa() {
    local ns=$1;shift
    local domain=$1;shift
    kubectl annotate svc uaa-uaa-public \
            -n "$ns" \
            "external-dns.alpha.kubernetes.io/hostname=uaa.${domain}, *.uaa.${domain}"
}

external_dns_annotate_stratos() {
    local ns=$1;shift
    local domain=$1;shift
    kubectl annotate svc suse-console-ui-ext \
            -n "$ns" \
            "external-dns.alpha.kubernetes.io/hostname=console.${domain}, *.console.${domain}"
}

external_dns_annotate_scf() {
    local ns=$1;shift
    local domain=$1;shift
    # for scf
    kubectl annotate svc router-gorouter-public \
            -n "$ns" \
            "external-dns.alpha.kubernetes.io/hostname=${domain}, *.${domain}"
    if [[ "${ENABLE_EIRINI}" == true ]] ; then
        kubectl annotate svc eirini-ssh-eirini-ssh-proxy-public \
                -n "$ns" \
                "external-dns.alpha.kubernetes.io/hostname=ssh.${domain}"
    else
        kubectl annotate svc diego-ssh-ssh-proxy-public \
                -n "$ns" \
                "external-dns.alpha.kubernetes.io/hostname=ssh.${domain}"
    fi
    kubectl annotate svc tcp-router-tcp-router-public \
            -n "$ns" \
            "external-dns.alpha.kubernetes.io/hostname=*.tcp.${domain}, tcp.${domain}"
}

# Convert yaml to json
y2j() {
    if [[ -e ${1:-} ]]; then
        ruby -r json -r yaml -e "puts YAML.load(File.read('$1')).to_json"
    else
        ruby -r json -r yaml -e 'puts (YAML.load(ARGF.read).to_json)'
    fi
}

# Convert json to yaml
j2y() {
    if [[ -e ${1:-} ]]; then
        ruby -r json -r yaml -e "puts YAML.dump(JSON.parse(File.read('$1')))"
    else
        ruby -r json -r yaml -e "puts YAML.dump(JSON.parse(ARGF.read))"
    fi
}

wait_for_cf-operator() {
    sleep 10

    wait_ns cf-operator

    wait_for "kubectl get endpoints -n cf-operator cf-operator-webhook -o name"
    wait_for "kubectl get crd quarksstatefulsets.quarks.cloudfoundry.org -o name"
    wait_for "kubectl get crd quarkssecrets.quarks.cloudfoundry.org -o name"
    wait_for "kubectl get crd quarksjobs.quarks.cloudfoundry.org -o name"
    wait_for "kubectl get crd boshdeployments.quarks.cloudfoundry.org -o name"
    info "Test CRDs are ready"
    #wait_for "kubectl apply -f ../kube/cf-operator/boshdeployment.yaml --namespace=scf"
    wait_for "kubectl apply -f ../kube/cf-operator/password.yaml --namespace=scf"
    if [[ "${DOCKER_REGISTRY}" == "registry.suse.com" ]]; then
      # qstate_tolerations fails when internet connectivity is disabled.
      wait_for "kubectl apply -f ../kube/cf-operator/qstatefulset_tolerations.yaml --namespace=scf"
    fi
    # Not waiting for kubecf, just for the toleration pod to be up and running
    wait_ns scf
    #wait_for "kubectl delete -f ../kube/cf-operator/boshdeployment.yaml --namespace=scf"
    wait_for "kubectl delete -f ../kube/cf-operator/password.yaml --namespace=scf"
    if [[ "${DOCKER_REGISTRY}" == "registry.suse.com" ]]; then
      wait_for "kubectl delete -f ../kube/cf-operator/qstatefulset_tolerations.yaml --namespace=scf"
    fi
}

wait_for_kubecf() {
    # There can be a brief moment when the "ig" job has terminated, but none of the
    # stateful sets have created a pod yet, where everything within the namespace
    # seems to be ready. That's why we also have to wait for the "api" pod to exist.
    #
    # There is a different scenario when one or more "ig" jobs have been launched by
    # quarks, and they seem to be in "completed" status and everything appears to be
    # "ready". But then one of the "ig" jobs restarts and terminates all the scf pods
    # again. So we need to wait until all the "ig" jobs are gone.
    wait_ns scf api ig
}
