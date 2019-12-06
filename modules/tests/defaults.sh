#!/usr/bin/env bash

# SMOKES option
###############

SMOKES_REPO="${SMOKES_REPO:-https://github.com/cloudfoundry/cf-smoke-tests}"

# CATS options
##############

CATS_REPO="${CATS_REPO:-https://github.com/cloudfoundry/cf-acceptance-tests}"

# BRATS options
###############

BRATS_CF_HOST="${BRATS_CF_HOST:-api.$DOMAIN}"
PROXY_HOST="${PROXY_HOST:-${public_ip}}"
PROXY_SCHEME="${PROXY_SCHEME:-http}"
BRATS_CF_USERNAME="${BRATS_CF_USERNAME:-admin}"
BRATS_CF_PASSWORD="${BRATS_CF_PASSWORD:-$CLUSTER_PASSWORD}"
PROXY_PORT="${PROXY_PORT:-9002}"
PROXY_USERNAME="${PROXY_USERNAME:-username}"
PROXY_PASSWORD="${PROXY_PASSWORD:-password}"
BRATS_TEST_SUITE="${BRATS_TEST_SUITE:-brats}"
CF_STACK="${CF_STACK:-sle15}"
GINKGO_ATTEMPTS="${GINKGO_ATTEMPTS:-3}"

BRATS_BUILDPACK="${BRATS_BUILDPACK}"
BRATS_BUILDPACK_URL="${BRATS_BUILDPACK_URL}"
BRATS_BUILDPACK_VERSION="${BRATS_BUILDPACK_VERSION}"

# Sample app options
####################

SAMPLE_APP_REPO="${SAMPLE_APP_REPO:-https://github.com/cloudfoundry-samples/cf-sample-app-nodejs}"
