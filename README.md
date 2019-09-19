# [![Build Status](https://travis-ci.com/SUSE/bkindwscf.svg?branch=master)](https://travis-ci.com/SUSE/bkindwscf) bkindwscf: [SCF](https://github.com/SUSE/scf) on top of [Kind](https://github.com/kubernetes-sigs/kind)

## Description

bkindwscf uses [kind](https://github.com/kubernetes-sigs/kind) to spin up a local kubernetes cluster from your Docker host with [SCF](https://github.com/SUSE/scf), mostly for development, demos and QA.

To use it in a CI, like travis, see the example [.travis.yml](https://github.com/SUSE/bkindwscf/blob/master/.travis.yml) file which is being used by this repository.


## How to run

**Requirements:**

* wget
* Helm (>2.12, https://github.com/helm/helm/issues/5054)
* Kubectl
* cf-cli (for logging and running smoke tests)
* Docker running on the host
* Go (only to run smoke and cats tests)

### Get deps:

#### Helm

    $> curl -L https://git.io/get_helm.sh | sudo bash

#### Kubectl

    $> curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

#### cf-cli

    $> curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
    $> mv cf /usr/local/bin
    $> chmod +x /usr/local/bin/cf

Clone this repository locally:

    $> git clone https://github.com/SUSE/bkindwscf

Then run the make targets inside the folder, see below for few examples. A new ```build/``` directory will be created inside after the kubernetes cluster is up.

    $> pushd bkindwscf
    $> make ...
    $> KUBECONFIG=build/kubeconfig kubectl get pods ...

Deploying [SCF](https://github.com/SUSE/scf) from the latest public chart is as simple as:

    $> make all

You can avoid to run all those jibberish (only if you don't care of your docker environment!) and have the same deployment using the bkindwscf docker image with:

    $> docker run -v /var/run/docker.sock:/var/run/docker.sock -ti --rm splatform/bkindwscf:latest dind

This will give you after a bit of waiting time a full bootstrapped SCF cluster.

Default user/pass: ```admin/password```

### From the docker image

You can build locally a docker image with bkindwscf:

    $> make image

Or you can use the docker image already built to start a cluster:

    $> docker run -v /var/run/docker.sock:/var/run/docker.sock --rm -ti splatform/bkindwscf:latest dind

To teardown:

    $> docker run -v /var/run/docker.sock:/var/run/docker.sock --rm -ti splatform/bkindwscf:latest force-clean

You can provide the same options as running it locally, but you have to pass the environment variables with ```-e``` prefixed.  e.g. ``` docker run -e CHART_URL=xxx -v /var/run/docker.sock:/var/run/docker.sock --rm -ti splatform/bkindwscf:latest kind docker-kubeconfig chart gen-config setup scf```

## Running options

The make targets can be executed separated, the only dependency is that some of them might require the cluster up.

### Creating a k8s cluster with kind

    $> make kind

The kubeconfig will be available under ```build/kubeconfig```.

#### Starting a cluster

    $> make start

#### Stopping a cluster

    $> make stop

#### Cleaning up

    $> make clean

Or if the cluster was started but the build dir was lost:

    $> make force-clean

To recover a kubeconfig from a previous deployment:

    $> make recover

### Upgrading a deployment

You might want to tweak the values file after a deployment, to experiment e.g. different env variables or upgrade from another chart.

To accomplish that, after you have a deployment running, edit the file ```build/scf-config-values.yaml``` and run ```make upgrade``` with the same options.

### Overriding a default stack

You can specify a default stack with ```DEFAULT_STACK```. e.g. to set a different default with an already existing deployment. You can just do:

    $> DEFAULT_STACK=cflinuxfs3 make gen-config upgrade

### Upgrading cf from a new chart

You can also test upgrades, by just providing a new chart, regenerating the configs and triggering an helm upgrade:

    $> CHART_URL="xxx" DEFAULT_STACK=cflinuxfs3 make chart gen-config upgrade

### Deploying from a specific chart url

Set the chart url in the ```CHART_URL``` variable.

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" make all

### Deploying with Diego

**Note** Currently this way of deployment isn't working

You need to disable eirini with: ```ENABLE_EIRINI=false```

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all

### Deploying SCFv3 (with cf-operator)

Setting `SCF_OPERATOR=true` enables SCFv3 deployment.
You can also tweak the CHART_URL to point to a specific chart, it defaults to latest from `v3-develop` branch in the SCF repository.

    $> SCF_OPERATOR=true make all

### Installing the Stratos console

You can run the ```stratos``` target separately after deployment or either append it to other targets:

    $> CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    ENABLE_EIRINI="false" \
    make all stratos

### Deploying from private Docker registries

You need to specify the following environment variables when running the make target:

```
    DOCKER_REGISTRY="my.private.registry"
    DOCKER_ORG="my-org"
    DOCKER_USERNAME="xxxx"
    DOCKER_PASSWORD="xxxx"
```

### Building and running SCF from source against a stemcell

    $> DOCKER_OPTS="-e FISSILE_STEMCELL=registry.some.org/org/fissile-stemcell:latest" make kind build-scf-from-source

## Deploying Eirini release from CF

    $> KIND_APIVERSION=kind.sigs.k8s.io/v1alpha3  KIND_VERSION=v0.4.0 make kind setup eirini-release

### Login in

Once the deployment of [SCF](https://github.com/SUSE/scf) succeeded, you can also manually login to your cluster if needed:

    $> make login

## Running Tests

You can also run smoke and cats tests against the deployed cluster:

### Smoke

    $> make smoke

### CATs

    $> make cats

If what you really want is just running tests, you can also chain the make target ( *e.g.* ```make all smoke cats```).

**Note**: You need go installed to run smoke and cats tests


## Using other k8s deployments

Apart from kind, one can deploy kubernetes on a different
flavour/infrastructure. Once k8s is deployed, the previous steps for deploying
scf, stratos, tests can be reused. Eg:

    $> CLUSTER_NAME=yourcaasp4os make all-caasp4os smoke

### minikube

Minikube allows you to have a k8s cluster with either docker, containerd, or
cri-o. By default you will get docker as container runtime, but you can select
which by passing the env var `MINIKUBE_RUNTIME`, with either `docker`,
`containerd` or `cri-o`.
You can obtain a minikube cluster with:

    $> CLUSTER_NAME=minikube make minikube

You can deploy SUSE Cloud Foundry on top with:

    $> CLUSTER_NAME=minikube make all-minikube

And delete your minikube VM with:

    $> CLUSTER_NAME=minikube make clean-minikube


### CaaSP4

#### Getting a CaaSP4 on Openstack configured for CAP

    $> CLUSTER_NAME=yourcaasp4os make all-caasp4os

This target gives you a CaaSP4 cluster, plus added NFS server, on Openstack. It
also configures the cluster for CAP.

It creates a docker skuba punctured image with the CaaSP4 product. With it, it
spawns the Openstack infrastructure by Terraform, bootstraps the cluster with
skuba (the CaaSP4 cli), and configures and prepares the cluster for cap by
adding correct RBACs, storageclasses, etc. It will build the skuba docker image
if not present.

Needs an Openstack's `openrc.sh` sourced for the terraform-openstack provider.
Adds an ssh key to ssh-agent if not present, and injects it into the machines.

#### Destroying the CaaSP4 deployment on Openstack

Since the infrastructure is living on Openstack, instead of deleting the
corresponding `build` folder, please run:

    $> CLUSTER_NAME=yourcaasp4os make clean-caasp4os

which first destroys the k8s storageclass (allowing a shared NFS server to
dispose of the shares) and then destroys the infrastructure on Openstack with
Terraform.
