#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Starting podman container and copying all imagelist.txt files there"

KUBECF_NAMESPACE=scf

# Create pod, waiting
kubectl apply --overwrite=false -f - << HEREDOC
---
apiVersion: v1
kind: Pod
metadata:
  name: push-imagelist-pod
  namespace: scf
spec:
  containers:
    - name: push-imagelist-pod
      image: greyarch/podman
      command:
      - /bin/sh
      - -c
      - |
        mkdir /tmp/kubecf
        mkdir /tmp/cf-operator
        echo >> /etc/containers/registries.conf
        echo '[registries.Insecure]' >> /etc/containers/registries.conf
        echo "registries = ['local-registry.default.svc.cluster.local']" >> /etc/containers/registries.conf
        apk add --no-cache skopeo
        while true; do sleep 100; done
HEREDOC

# create push-imagelist.sh script
cat >push-imagelist.sh << 'HEREDOC'
#!/usr/bin/env sh

set -e

while IFS= read -r file
do
    for SOURCE_IMAGE in $(cat "$imagelist_file"); do
        MIRROR='local-registry.default.svc.cluster.local'
        echo ">>>>> Mirroring image: ${SOURCE_IMAGE}"
        # add registry.suse.com/cap/ in front if it's not already there
        if [[ $( echo $SOURCE_IMAGE | grep -o '/' | tr -d '\r\n' | wc -c) -lt 1 ]]; then
            # SOURCE_IMAGE=docker.io/"$SOURCE_IMAGE" # upstream
            SOURCE_IMAGE=registry.suse.com/cap/$SOURCE_IMAGE # cap
        fi

        org=$(echo "$SOURCE_IMAGE" | cut -d/ -f2)
        image=$(echo "$SOURCE_IMAGE" | cut -d/ -f3)

        skopeo copy "docker://${SOURCE_IMAGE}" "docker://${MIRROR}/${org}/${image} 2>&1 >/dev/null" &
    done
done <  <(find . -name "imagelist.txt")


wait
echo
echo "Done pushing images"
HEREDOC
chmod +x push-imagelist.sh

# wait for the pod to be up
sleep 30

# copy push-imagelist.sh script
kubectl cp  push-imagelist.sh "${KUBECF_NAMESPACE}"/push-imagelist-pod:/tmp/push-imagelist.sh

# copy all imagelist.txt files
while IFS= read -r imagelist_file
do
    kubectl cp -n "${KUBECF_NAMESPACE}" "$imagelist_file" \
            "${KUBECF_NAMESPACE}"/push-imagelist-pod:/tmp/"$imagelist_file"
done <  <(find . -name "imagelist.txt")

# start the script in the pod
# TODO
# for now, just cd tmp; ./push-imagelist.sh
