#!/usr/bin/env bash

# SMOKES option
###############

export SMOKES_REPO="${SMOKES_REPO:-https://github.com/cloudfoundry/cf-smoke-tests}"

# CATS options
##############

export CATS_REPO="${CATS_REPO:-https://github.com/cloudfoundry/cf-acceptance-tests}"

# BRATS options
###############

export PROXY_SCHEME="${PROXY_SCHEME:-http}"
export BRATS_CF_USERNAME="${BRATS_CF_USERNAME:-admin}"
export BRATS_CF_PASSWORD="${BRATS_CF_PASSWORD:-$CLUSTER_PASSWORD}"
export PROXY_PORT="${PROXY_PORT:-9002}"
export PROXY_USERNAME="${PROXY_USERNAME:-username}"
export PROXY_PASSWORD="${PROXY_PASSWORD:-password}"
export BRATS_TEST_SUITE="${BRATS_TEST_SUITE:-brats}"
export CF_STACK="${CF_STACK:-sle15}"
export GINKGO_ATTEMPTS="${GINKGO_ATTEMPTS:-3}"

export BRATS_BUILDPACK="${BRATS_BUILDPACK}"
export BRATS_BUILDPACK_URL="${BRATS_BUILDPACK_URL}"
export BRATS_BUILDPACK_VERSION="${BRATS_BUILDPACK_VERSION}"

# Sample app options
####################

export SAMPLE_APP_REPO="${SAMPLE_APP_REPO:-https://github.com/cloudfoundry-samples/cf-sample-app-nodejs}"

# KubeCF tests options
######################

export KUBECF_CHECKOUT="${KUBECF_CHECKOUT:-}"
export KUBECF_TEST_SUITE="${KUBECF_TEST_SUITE:-smokes}" # smokes, sits, brain, cats, cats-internetless
export KUBECF_DEPLOYMENT_NAME="${KUBECF_DEPLOYMENT_NAME:-susecf-scf}"
export KUBECF_NAMESPACE="${KUBECF_NAMESPACE:-scf}"
