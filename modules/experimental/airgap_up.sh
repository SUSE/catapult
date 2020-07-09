#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [[ ${BACKEND} != "caasp4os" ]]; then
  err "airgap simulation only works with caasp4os type backends"
  exit 1
fi

airgap_up_node() {
  local kube_node=$1
  info "Adding airgap iptables rules for ${kube_node}"
  local host_ip=$(ssh sles@$kube_node 'echo $SSH_CONNECTION' | awk '{ print $1 }')
  if ! grep -qE "([0-9]{1,3}\.){3}[0-9]{1,3}" <<< $host_ip; then
    err "Couldn't get catapult host IP from CaaSP node for iptables whitelist"
    exit 1
  fi
  ssh -T sles@${kube_node} << EOF
sudo -s << 'EOS'
  iptables -A OUTPUT -j ACCEPT -d ${host_ip}
  iptables -A OUTPUT -j ACCEPT -d 0.0.0.0
  iptables -A OUTPUT -j ACCEPT -d 10.0.0.0/8
  iptables -A OUTPUT -j ACCEPT -d 100.64.0.0/10
  iptables -A OUTPUT -j ACCEPT -d 127.0.0.0/8
  iptables -A OUTPUT -j ACCEPT -d 172.16.0.0/12
  iptables -A OUTPUT -j ACCEPT -d 192.168.0.0/16
  iptables -A OUTPUT -j DROP -d 0.0.0.0/0
EOS
EOF
}

# --selector '!node-role.kubernetes.io/master'
kube_nodes=$(kubectl get nodes -o json | jq -r '.items[] | .status.addresses[] | select(.type=="InternalIP").address')
for kube_node in ${kube_nodes}; do
  airgap_up_node ${kube_node}
done

info "Cluster ${CLUSTER_NAME} is now running a simulated airgapped setup. Run \`make module-experimental-airgap-down\` to restore internet access"

