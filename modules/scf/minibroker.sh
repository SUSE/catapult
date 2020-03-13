#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

# delete previous deployments
if cf service-brokers 2>/dev/null | grep -qi minibroker ; then
    cf delete-service-broker minibroker -f
fi
if helm ls 2>/dev/null | grep -qi minibroker ; then
    helm_delete minibroker
fi
if kubectl get namespaces 2>/dev/null | grep -qi minibroker ; then
    kubectl delete namespace minibroker
fi

ORG=$(cf target | grep "org:" | tr -s " " | cut -d " " -f 2)

helm_install minibroker suse/minibroker --namespace minibroker --set "defaultNamespace=minibroker"

wait_ns minibroker

# username and password are dummies
cf create-service-broker minibroker username password http://minibroker-minibroker.minibroker.svc.cluster.local

cf service-brokers

info "Listing services and plans that the minibroker service has access to:"
cf service-access -b minibroker

info "Enabling postgresql service"
cf enable-service-access postgresql -b minibroker -p 11-6-0
echo > postgresql.json '[{ "protocol": "tcp", "destination": "10.0.0.0/8", "ports": "5432", "description": "Allow PostgreSQL traffic" }]'
cf create-security-group postgresql_networking postgresql.json
cf bind-security-group postgresql_networking $ORG

info "Enabling redis service"
cf enable-service-access redis -b minibroker -p 5-0-7
echo > redis.json '[{ "protocol": "tcp", "destination": "10.0.0.0/8", "ports": "6379", "description": "Allow Redis traffic" }]'
cf create-security-group redis_networking redis.json
cf bind-security-group redis_networking $ORG

info "Create postgresql service"
cf create-service postgresql 11-6-0 postgresql-service
wait_ns minibroker

info "Create redis service"
cf create-service redis 5-0-7 redis-service
wait_ns minibroker

ok "Deployed minibroker and services successfully"
