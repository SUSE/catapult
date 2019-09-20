# [![Build Status](https://travis-ci.com/SUSE/bkindwscf.svg?branch=master)](https://travis-ci.com/SUSE/bkindwscf) bkindwscf: [SCF](https://github.com/SUSE/scf) on top of [Kind](https://github.com/kubernetes-sigs/kind) (and others..)

Get your local development [SCF](https://github.com/SUSE/scf) install with:

    $> docker run -v /var/run/docker.sock:/var/run/docker.sock -ti --rm splatform/bkindwscf:latest dind
    
Check out [Run in Docker](https://github.com/SUSE/bkindwscf/wiki/Run-in-Docker) page on the wiki for more options.
 
## Description

bkindwscf uses [kind](https://github.com/kubernetes-sigs/kind) (and other backends, like `minikube`, `caasp`, `ekcp`...) to spin up a local kubernetes cluster from your Docker host (or bootstrap it remotely) with [SCF](https://github.com/SUSE/scf), mostly for development, demos and QA.

To use it in a CI, like travis, see the example [.travis.yml](https://github.com/SUSE/bkindwscf/blob/master/.travis.yml) file which is being used by this repository.

[Checkout the wiki](https://github.com/SUSE/bkindwscf/wiki) and the [First step](https://github.com/SUSE/bkindwscf/wiki/First-steps) page to see how to use it.
