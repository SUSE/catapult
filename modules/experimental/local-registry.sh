#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

info "Creating local registry at local-registry.default.svc.cluster.local…"

kubectl apply -f - <<HEREDOC
---
# PVC for local registry service
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: registry-data-pvc
  labels:
    app: local-registry
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 30Gi
---
# Docker registry pod definition
apiVersion: v1
kind: Pod
metadata:
  name: local-registry
  labels:
    app: local-registry
  namespace: default
spec:
  volumes:
    - name: registry-data-vol
      persistentVolumeClaim:
        claimName: registry-data-pvc
  containers:
    - name: local-registry
      image: registry:2
      imagePullPolicy: Always
      ports:
        - containerPort: 5000
      volumeMounts:
        - mountPath: /var/lib/registry
          name: registry-data-vol
---
# Registry service definition
kind: Service
apiVersion: v1
metadata:
  name: local-registry
  namespace: default
spec:
  selector:
    app: local-registry
  ports:
    - port: 80
      targetPort: 5000
HEREDOC

wait_ns default

ok "Registry created"
kubectl get services local-registry -n default
