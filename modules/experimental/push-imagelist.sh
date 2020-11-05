#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Pushing all imagelist.txt images to local-registry.default.svc.cluster.local"

kubectl create namespace push-imagelist 2>/dev/null || true

# POSIX compliant:
while IFS= read -r imagelist_file
do
    # Create a kube job per image in imagelist.txt. There, pull it, retag it,
    # and push the image to the local registry
    for SOURCE_IMAGE in $(cat "$imagelist_file"); do
        JOB_NAME=${SOURCE_IMAGE%%\:*} # remove suffix after ':'
        JOB_NAME=${JOB_NAME////-} # substitute '/' with '-'
        JOB_NAME=${JOB_NAME:0:63} # truncate to 63 charts for kubernetes
        TARGET_REGISTRY='local-registry.default.svc.cluster.local'
        kubectl apply --overwrite=false -f - <<HEREDOC
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: push-imagelist
spec:
  template:
    spec:
      containers:
      - name: copy-image
        image: dragonchaser/opensuse-skopeo:latest
        command:
        - /bin/sh
        - -cex
        - |
          echo >> /etc/containers/registries.conf
          echo '[registries.Insecure]' >> /etc/containers/registries.conf
          echo "registries = ['${TARGET_REGISTRY}']" >> /etc/containers/registries.conf

          # add registry.suse.com/cap/ in front if it's not already there
          if [[ $( echo "$SOURCE_IMAGE" | grep -o '/' | tr -d '\r\n' | wc -c) -lt 1 ]]; then
              # SOURCE_IMAGE=docker.io/"$SOURCE_IMAGE" # upstream
              SOURCE_IMAGE=registry.suse.com/cap/$SOURCE_IMAGE # cap
          fi

          org=\$(echo \$SOURCE_IMAGE | cut -d/ -f2)
          image=\$(echo \$SOURCE_IMAGE | cut -d/ -f3)

          echo "Mirroring image \$SOURCE_IMAGE to ${TARGET_REGISTRY}"
          skopeo copy "docker://\${SOURCE_IMAGE}" "docker://${TARGET_REGISTRY}/\$org/\$image"
          echo "Mirrored image \$SOURCE_IMAGE in ${TARGET_REGISTRY}"
      restartPolicy: Never
  backoffLimit: 4
HEREDOC
    done
done <  <(find . -name "imagelist.txt")

info "Waiting for jobs to finish pushing images…"
kubectl -n push-imagelist wait --for=condition=complete job --all --timeout=-1s

ok "All images pushed to local-registry.default.svc.cluster.local"
