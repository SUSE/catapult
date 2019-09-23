#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

domain=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["domain"]')
public_ip=$(kubectl get configmap -n kube-system cap-values -o json | jq -r '.data["public-ip"]')
aux_external_ips=($(kubectl get nodes -o json | jq -r '.items[].status.addresses[] | select(.type == "InternalIP").address'))
external_ips+="\"$public_ip\""
for (( i=0; i < ${#aux_external_ips[@]}; i++ )); do
external_ips+=", \"${aux_external_ips[$i]}\""
done

cat > nginx_proxy_deployment.yaml <<EOF
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-proxy-deployment
spec:
  selector:
    matchLabels:
      app: nginx-proxy
  template:
    metadata:
      labels:
        app: nginx-proxy
    spec:
      containers:
      - name: nginx-proxy
        image: quay.io/dtan4/nginx-basic-auth-proxy
        ports:
        - containerPort: 80
        env:
        - name: SERVER_NAME
          value: "${domain}" # This should match the caasp master's floating ip
        - name: BASIC_AUTH_USERNAME
          value: "username"
        - name: BASIC_AUTH_PASSWORD
          value: "password"
        - name: PROXY_PASS
          value: "https://s3.amazonaws.com/" # Change this to "https://download.opensuse.org/" for OBS hosted dependencies
        - name: PORT
          value: "80"
EOF

kubectl create -f nginx_proxy_deployment.yaml

cat > nginx_proxy_service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: nginx-proxy
  labels:
    run: nginx-proxy
spec:
  externalIPs: [${external_ips}]  # This should match the caasp master's "internal" ip (not the floating one)
  ports:
  - port: 9002
    protocol: TCP
    targetPort: 80
  selector:
    app: nginx-proxy
EOF

kubectl create -f nginx_proxy_service.yaml

cat > securitygroup.json <<EOF
[
        {
                "destination": "${public_ip}",
                "ports": "9002",
                "protocol": "tcp"
        }
]
EOF

cf create-security-group nginx_proxy securitygroup.json
cf bind-running-security-group nginx_proxy
cf bind-staging-security-group nginx_proxy
