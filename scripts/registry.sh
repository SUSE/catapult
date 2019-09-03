#!/bin/bash
set -ex

. scripts/include/common.sh
. .envrc

# From: https://github.com/windmilleng/kind-local

nodes=$(kubectl get nodes -oname)
num_nodes=$(echo "$nodes" | wc -l | sed 's/^ *//')

# double-check that we have a 1-node cluster
if [[ "1" != "$num_nodes" ]]; then
    echo "Required: KIND cluster with exactly 1 node. Actual: $num_nodes"
    exit 1
fi


# Edit the containerd config on each node
for node in $(kubectl get nodes -oname); do
    node_name=${node#node/}

    echo "node_name: ${node_name}"

    # Check to see if containerd is set up already with an insecure registry
    config=$(docker exec ${node_name} cat /etc/containerd/config.toml)
    if [[ "$config" != *"localhost:32001"* ]]; then
        echo "Overwriting /etc/containerd/config.toml"

        # Overwrite config.toml with our own
        docker cp ../config/config.toml ${node_name}:/etc/containerd/config.toml

        # Restart the kubelet
        docker exec ${node_name} systemctl restart kubelet.service
    else
        echo "Containerd already aware of private registry"
    fi
done

set -ex
kubectl apply -f ../kube/registry.yaml
sleep 10
bash ../scripts/wait.sh container-registry
kubectl port-forward -n container-registry service/registry 32001:5000