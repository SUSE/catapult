# [![Build Status](https://travis-ci.org/os-fun/bkindwscf.svg?branch=master)](https://travis-ci.org/os-fun/bkindwscf) bkindwscf: Quickly deploy SCF on kind

**Requirements:**

* wget
* Helm
* Kubectl
* Docker running on the host

Turn on a SCF+Kind cluster with:

    CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    make all

## Running options

### Eirini disabled

    CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all

### Install the Stratos console

    CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all stratos

### Stop a cluster

    make stop

### Start a cluster

    make start

### Create a fresh kubernetes cluster with kind

    make kind

The kubeconfig will be available under ```build/kubeconfig```.

## Example

Deploy SCF from public chart:

    CHART_URL="https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" \
    DOCKER_REGISTRY="registry.suse.com" \
    DOCKER_ORG="cap" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    make all
