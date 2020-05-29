#!/usr/bin/env bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

curl -Lo klog.sh "$SCF_REPO"/raw/"$SCF_BRANCH"/dev/kube/klog.sh
chmod +x klog.sh
mv klog.sh bin/

HOME=${BUILD_DIR} klog.sh -f ${KUBECF_NAMESPACE} 
