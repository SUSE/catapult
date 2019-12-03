
# NOTE: BACKEND is dup in include/common.sh to allow BACKEND override when loading from json config files
BACKEND?=kind
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := all

# Defaults non-existing make targets to the backend
.DEFAULT:
	make -C backend/$(BACKEND) "$@"

private:
	make -C $(filter-out $@, $(MAKECMDGOALS))

.PHONY: buildir
buildir:
	include/buildir.sh

# General targets (Public)
.PHONY: clean
clean:
	make -C backend/$(BACKEND) clean

.PHONY: k8s
k8s: clean buildir
	make -C modules/common
	make -C backend/$(BACKEND)

.PHONY: kubeconfig
kubeconfig:
	make -C backend/$(BACKEND) kubeconfig

.PHONY: start
start:
	make -C backend/$(BACKEND) start

.PHONY: stop
stop:
	make -C backend/$(BACKEND) stop

.PHONY: restart
restart:
	make -C backend/$(BACKEND) restart

.PHONY: recover
recover: buildir kubeconfig

.PHONY: force-clean
force-clean: buildir clean

.PHONY: all
all: scf-deploy scf-login

# kind targets:

.PHONY: recover-or-kind
recover-or-kind:
	make -C backend/kind deps up-if-not-exists kubeconfig

.PHONY: dind
dind: clean buildir
	make -C backend/kind deps up kubeconfig docker-kubeconfig prepare
	make scf

# catapult-only targets:

.PHONY: catapult-test
catapult-test:
	make -C tests

.PHONY: catapult-lint
catapult-lint:
	make -C tests lint

.PHONY: catapult-image
catapult-image:
	scripts/image.sh

# extra targets:
.PHONY: module-extra-concourse
module-extra-concourse:
	make -C modules/extra concourse

.PHONY: module-extra-ingress
module-extra-ingress:
	make -C modules/extra ingress

.PHONY: module-extra-ingress-forward
module-extra-ingress-forward:
	make -C modules/extra ingress-forward

.PHONY: module-extra-kwt
module-extra-kwt:
	make -C modules/extra kwt

.PHONY: module-extra-kwt-connect
module-extra-kwt-connect:
	make -C modules/extra kwt-connect

.PHONY: module-extra-task
module-extra-task:
	make -C modules/extra task

.PHONY: module-extra-terminal
module-extra-terminal:
	make -C modules/extra terminal

.PHONY: module-extra-catapult-web
module-extra-catapult-web:
	make -C modules/extra web

.PHONY: module-extra-registry
module-extra-registry:
	make -C modules/extra registry

.PHONY: module-extra-brats-setup
module-extra-brats-setup:
	make -C modules/scf scf-brats-setup

## Experimental
.PHONY: module-experimental-eirinifs
module-experimental-eirinifs:
	make -C modules/experimental eirinifs

.PHONY: module-experimental-eirini_release
module-experimental-eirini_release:
	make -C modules/experimental eirini_release

# scf-only targets:
.PHONY: scf-deploy
scf-deploy: clean buildir
	make k8s kubeconfig scf

.PHONY: scf-clean
scf-clean:
	make -C modules/scf clean

.PHONY: scf
scf:
	make -C modules/scf

.PHONY: scf-login
scf-login:
	make -C modules/scf login

.PHONY: scf-gen-config
scf-gen-config:
	make -C modules/scf gen-config

.PHONY: scf-upgrade
scf-upgrade:
	make -C modules/scf upgrade

.PHONY: scf-chart
scf-chart:
	make -C modules/common
	make -C modules/scf chart

.PHONY: scf-build
scf-build:
	make -C modules/scf build-scf-from-source
	make scf-gen-config
	make -C modules/scf install

.PHONY: scf-purge
scf-purge:
	make -C modules/scf purge

.PHONY: scf-build-stemcell
scf-build-stemcell:
	make -C modules/scf stemcell_build

# stratos-only targets:
.PHONY: stratos
stratos:
	make -C modules/stratos

.PHONY: stratos-clean
stratos-clean:
	make -C modules/stratos clean

.PHONY: stratos-chart
stratos-chart:
	make -C modules/stratos chart

.PHONY: stratos-gen-config
stratos-gen-config:
	make -C modules/stratos gen-config

.PHONY: stratos-upgrade
stratos-upgrade:
	make -C modules/stratos upgrade

# metrics-only targets:
.PHONY: metrics
metrics:
	make -C modules/metrics

.PHONY: metrics-clean
metrics-clean:
	make -C modules/metrics clean

.PHONY: metrics-chart
metrics-chart:
	make -C modules/metrics chart

.PHONY: metrics-gen-config
metrics-gen-config:
	make -C modules/metrics gen-config

.PHONY: metrics-upgrade
metrics-upgrade:
	make -C modules/metrics upgrade

# test-only targets:
.PHONY: tests
tests:
	make -C modules/tests

.PHONY: tests-smoke
tests-smoke:
	make -C modules/tests smoke

.PHONY: tests-smoke-kube
tests-smoke-kube:
	make -C modules/tests smoke-kube

.PHONY: tests-kubecats
tests-kubecats:
	make -C modules/tests kubecats

.PHONY: tests-brats
tests-brats:
	make -C modules/tests brats

.PHONY: tests-eirini-persi
tests-eirini-persi:
	make -C modules/tests test-eirini-persi

.PHONY: tests-smoke-scf
tests-smoke-scf:
	make -C modules/tests smoke-scf

.PHONY: tests-cats
tests-cats:
	make -C modules/tests cats

# Samples and fixtures
.PHONY: sample
sample:
	make -C modules/tests sample

.PHONY: sample-ticking
sample-ticking:
	make -C modules/tests sample-ticking

# Deprecated targets:

.PHONY: kind
kind::
	@echo 'WARNING: target deprecated. Please use `make k8s` or `BACKEND=kind make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
kind:: clean buildir
	make -C backend/kind
	make kubeconfig

.PHONY: gke
gke::
	@echo 'WARNING: target deprecated. Please use `BACKEND=gke make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
gke:: clean buildir
	make -C backend/gke

.PHONY: eks
eks::
	@echo 'WARNING: target deprecated. Please use "BACKEND=eks make k8s" instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
eks:: clean buildir
	make -C backend/eks

.PHONY: minikube
minikube::
	@echo 'WARNING: target deprecated. Please use "BACKEND=minikube make k8s" instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
minikube:: clean buildir
	make -C backend/minikube

.PHONY: all-minikube
all-minikube::
	@echo 'WARNING: target deprecated. Please use "BACKEND=minikube make all" instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
all-minikube:: minikube scf

.PHONY: all-caasp4os
all-caasp4os::
	@echo 'WARNING: target deprecated. Please use `BACKEND=caasp4os make all` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
all-caasp4os:: caasp4os scf

.PHONY: all-gke
all-gke::
	@echo 'WARNING: target deprecated. Please use `BACKEND=gke make all` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
all-gke:: gke scf

.PHONY: caasp4os-clean
caasp4os-clean::
	@echo 'WARNING: target deprecated. Please use `BACKEND=caasp4os make clean` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
caasp4os-clean::
	make -C backend/caasp4os clean

.PHONY: caasp4os
caasp4os::
	@echo 'WARNING: target deprecated. Please use `BACKEND=caasp4os make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
caasp4os:: caasp4os-clean buildir
	make -C backend/caasp4os

.PHONY:image
image::
	@echo 'WARNING: target deprecated. Please use `make catapult-image` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
image:: catapult-image
