#!/bin/bash
set -ex

. scripts/include/common.sh

cp $(./kind get kubeconfig-path --name="$cluster_name") kubeconfig