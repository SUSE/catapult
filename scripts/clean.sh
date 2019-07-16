#!/bin/bash
set -x
DEEP_CLEAN="${DEEP_CLEAN:-false}"

if [ -d build ]; then
  pushd build
      export KUBECONFIG=kubeconfig
      if [ "$DEEP_CLEAN" = true ] ; then
        helm del --purge susecf-uaa
        helm del --purge susecf-scf
        kubectl delete secret --all
        kubectl delete pod --all -n eirini
        kubectl delete pvc --all -n eirini
        kubectl delete pod --all -n cf
        kubectl delete secret --all -n eirini
      fi
      helm reset --force
      ./kind delete cluster
  popd

  rm -rf build
fi
