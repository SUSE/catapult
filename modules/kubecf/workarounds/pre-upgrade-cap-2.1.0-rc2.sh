#!/usr/bin/env bash

info "WORKAROUND CAP 2.1.0-rc2"
kubectl delete qjob --namespace scf dm
