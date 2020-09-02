#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc || exit 0

if [[ ${BACKEND} != "caasp4os" ]]; then
  info "airgap simulation only works with caasp4os type backends. No airgap rules to clean"
  exit 0
fi

airgap_down_node() {
  local kube_node host_ip
  kube_node=$1
  info "Removing airgap iptables rules for ${kube_node}"
  host_ip=$(ssh sles@$kube_node 'echo $SSH_CONNECTION' | awk '{ print $1 }')
  if ! grep -qE "([0-9]{1,3}\.){3}[0-9]{1,3}" <<< $host_ip; then
    err "Couldn't get catapult host IP from CaaSP node for iptables whitelist"
    exit 1
  fi
  # shellcheck disable=SC2087
  ssh -T sles@${kube_node} << EOF
sudo -s << 'EOS'
  if iptables -D OUTPUT -j DROP -d 0.0.0.0/0 2>/dev/null; then
    iptables -D OUTPUT -j ACCEPT -d ${host_ip} 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 0.0.0.0 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 10.0.0.0/8 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 100.64.0.0/10 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 127.0.0.0/8 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 172.16.0.0/12 2>/dev/null || true
    iptables -D OUTPUT -j ACCEPT -d 192.168.0.0/16 2>/dev/null || true
  else
    echo "Could not remove DROP 0.0.0.0/0 in OUTPUT chain. Skipping other iptable deletions"
  fi
EOS
EOF
}

kube_nodes=$(kubectl get nodes -o json | jq -r '.items[] | .status.addresses[] | select(.type=="InternalIP").address')
kube_nodes_unreachable=$(kubectl get nodes -o json | jq -C -r '[.items[] |  select((.spec.taints // [])[] | .key == "node.kubernetes.io/unreachable") | .status.addresses[] | select(.type=="InternalIP").address] | unique[]')
kube_nodes_reachable=$(comm -23 <(echo "${kube_nodes}") <(echo "${kube_nodes_unreachable}"))
for kube_node in ${kube_nodes_reachable}; do
  airgap_down_node ${kube_node}
done
kubectl delete --ignore-not-found -n cf-operator -f ../modules/experimental/cilium-block-egress.yaml
kubectl delete --ignore-not-found -n scf -f ../modules/experimental/cilium-block-egress.yaml
