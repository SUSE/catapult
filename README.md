# [![Build Status](https://travis-ci.com/SUSE/catapult.svg?branch=master)](https://travis-ci.com/SUSE/catapult) Catapult

    $> git clone https://github.com/SUSE/catapult.git && cd catapult
    $> make all

This will start a local [Kind](https://github.com/kubernetes-sigs/kind) cluster
and deploy kubecf on top of it. Remove everything with `make clean`.

Next, check the [First steps wiki page](https://github.com/SUSE/catapult/wiki/First-steps)
or do:

    $> make help
    $> make help-all


# Description

Catapult is a CI implementation for [KubeCF](https://github.com/SUSE/kubecf),
[SCF](https://github.com/SUSE/scf) &
[Stratos](https://github.com/cloudfoundry/stratos),
designed from the ground-up to work locally. This allows iterating and using it
for manual tests and development of the products, in addition to running it in
your favourite CI scheduler (Concourse, Gitlab…).

Catapult supports several k8s backends: can create CaaSP4, GKE, EKS clusters on its
own, and you can bring your own cluster with the "imported" backend.

It is implemented as a little lifecycle manager (a finite state machine), written
with Makefiles and Bash scripts.

The deployments achieved with Catapult are not production ready; don't expect
them to be in the future either. They are for developing and testing.

It also contains some goodies to aid in development and testing deployments (see
`make module-extra-*`).

To use it in a CI, like travis, see for example:
* [.travis.yml](https://github.com/SUSE/catapult/blob/master/.travis.yml) on this
repository, to CI Catapult itself
* [kubecf post-publish](https://github.com/SUSE/kubecf/tree/master/.concourse)

# Documentation

For now, all documentation is in the [project wiki](https://github.com/SUSE/catapult/wiki).

# Contributing

Please run catapult's linting, unit tests, integration tests, etc for a full TDD
experience, as PRs are gated through them (see "build status" label):

     $> make catapult-tests

Debug catapult with `DEBUG_MODE=true`.

You can get your local development for [SCF](https://github.com/SUSE/scf)
or [KubeCF](https://github.com/SUSE/kubecf), with all needed catapult deps, with:

    $> docker run -v /var/run/docker.sock:/var/run/docker.sock -ti --rm splatform/catapult:latest dind

Check out [Run in Docker](https://github.com/SUSE/catapult/wiki/Run-in-Docker)
page on the wiki for more options.
