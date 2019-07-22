# [![Build Status](https://travis-ci.org/os-fun/bkindwscf.svg?branch=master)](https://travis-ci.org/os-fun/bkindwscf) bkindwscf: Quickly deploy [SCF](https://github.com/SUSE/scf) on [Kind](https://github.com/kubernetes-sigs/kind)

**Requirements:**

* wget
* Helm
* Kubectl
* cf-cli (for logging and running smoke tests)
* Docker running on the host

## Get deps:

### Helm
        $> curl -L https://git.io/get_helm.sh | sudo bash

### Kubectl
        $> curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
        && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

### cf-cli

        $> curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
        $> mv cf /usr/local/bin
        $> chmod +x /usr/local/bin/cf

Then you can turn on a [SCF](https://github.com/SUSE/scf)+[Kind](https://github.com/kubernetes-sigs/kind) cluster just with:

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="xxxx" \
    DOCKER_PASSWORD="xxxx" \
    make all

It will use [kind](https://github.com/kubernetes-sigs/kind) to spin up a local kubernetes cluster from your Docker host.

To use it in a CI, like travis, see the example [.travis.yml](https://github.com/os-fun/bkindwscf/blob/master/.travis.yml) file which is being used by this repository.

## How to run

Clone this repository locally:

    $> git clone https://github.com/os-fun/bkindwscf

Then run the make targets inside the folder, see below for few examples. A new ```build/``` directory will be created inside after the kubernetes cluster is up.

    $> pushd bkindwscf
    $> make ...
    $> KUBECONFIG=build/kubeconfig kubectl get pods ...

## Running options

The make targets can be executed separated, the only dependency is that some of them might require the cluster up.

### Create a fresh kubernetes cluster with kind

    $> make kind

The kubeconfig will be available under ```build/kubeconfig```.

### Start a cluster

    $> make start

### Stop a cluster

    $> make stop

### Upgrade a release

You might want to tweak the values file after a deployment, to experiment e.g. different env variables.

To accomplish that, after you have a deployment running, edit the file ```build/scf-config-values.yaml``` and run ```make upgrade``` with the same options.

### Override a default stack

You can specify a default stack with ```DEFAULT_STACK```. e.g. to set a different default with an already existing deployment. You can just do:

    $> DEFAULT_STACK=cflinuxfs3 make gen-config upgrade

### Upgrade cf from a new chart

You can also test upgrades, by just providing a new chart, regenerating the configs and triggering an helm upgrade:

    $> CHART_URL="xxx" DEFAULT_STACK=cflinuxfs3 make chart gen-config upgrade

### Deploy with Diego

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all

### Install the Stratos console

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all stratos

## Run Tests 

You can run smoke and cats tests against the deployed cluster:

### Smoke

    make smoke

### CATs

    make cats

If what you really want is just running tests, you can also chain the make target ( *e.g.* ```make all smoke cats```).

## Example

Deploy [SCF](https://github.com/SUSE/scf) from public chart:

    $> CHART_URL="https://github.com/SUSE/scf/releases/download/2.16.4/scf-sle-2.16.4+cf6.10.0.2.g5abdb16f.zip" \
    DOCKER_REGISTRY="registry.suse.com" \
    DOCKER_ORG="cap" \
    make all
