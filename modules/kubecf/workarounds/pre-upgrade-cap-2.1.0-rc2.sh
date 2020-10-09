#!/usr/bin/env bash

info "Applying WORKAROUND $(basename ${BASH_SOURCE[0]})"
set +x # print workaround

kubectl delete qjob --namespace scf dm --ignore-not-found

debug_mode # reset printing option
