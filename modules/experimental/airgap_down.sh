#!/usr/bin/env bash

#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [[ ${BACKEND} != "caasp4os" ]]; then
  err "airgap simulation only works with caasp4os type backends"
  exit 1
fi

airgap_down_node() {
  local kube_node=$1
  info "Removing airgap iptables rules for ${kube_node}"
  local host_ip=$(ssh sles@$kube_node 'echo $SSH_CONNECTION' | awk '{ print $1 }')
  if ! grep -qE "([0-9]{1,3}\.){3}[0-9]{1,3}" <<< $host_ip; then
    err "Couldn't get catapult host IP from CaaSP node for iptables whitelist"
    exit 1
  fi
  ssh -T sles@${kube_node} << EOF
sudo -s << 'EOS'
  if ! iptables -D OUTPUT -j DROP -d 0.0.0.0/0 2>/dev/null; then
    echo "Could not remove DROP 0.0.0.0/0 in OUTPUT chain. Aborting"
    exit
  fi
  iptables -D OUTPUT -j ACCEPT -d ${host_ip} 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 0.0.0.0 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 10.0.0.0/8 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 100.64.0.0/10 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 127.0.0.0/8 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 172.16.0.0/12 2>/dev/null || true
  iptables -D OUTPUT -j ACCEPT -d 192.168.0.0/16 2>/dev/null || true
EOS
EOF
}

# --selector '!node-role.kubernetes.io/master'
kube_nodes=$(kubectl get nodes -o json | jq -r '.items[] | .status.addresses[] | select(.type=="InternalIP").address')
for kube_node in ${kube_nodes}; do
  airgap_down_node ${kube_node}
done
