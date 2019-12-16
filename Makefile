ifneq ($(DEBUG_MODE),true)
	MAKE=make -s
endif

# NOTE: BACKEND is dup in include/common.sh to allow BACKEND override when loading from json config files
BACKEND?=kind
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

.DEFAULT_GOAL := all

# Defaults non-existing make targets to the backend
.DEFAULT:
	$(MAKE) -C backend/$(BACKEND) "$@"

private:
	$(MAKE) -C $(filter-out $@, $(MAKECMDGOALS))

.PHONY: buildir
buildir:
	include/buildir.sh

# General targets (Public)
.PHONY: clean
clean:
	$(MAKE) -C backend/$(BACKEND) clean

.PHONY: k8s
k8s: clean buildir
	$(MAKE) -C modules/common
	$(MAKE) -C backend/$(BACKEND)

.PHONY: kubeconfig
kubeconfig:
	$(MAKE) -C backend/$(BACKEND) kubeconfig

.PHONY: start
start:
	$(MAKE) -C backend/$(BACKEND) start

.PHONY: stop
stop:
	$(MAKE) -C backend/$(BACKEND) stop

.PHONY: restart
restart:
	$(MAKE) -C backend/$(BACKEND) restart

.PHONY: recover
recover: buildir kubeconfig

.PHONY: force-clean
force-clean: buildir clean

.PHONY: all
all: scf-deploy scf-login

# kind targets:

.PHONY: recover-or-kind
recover-or-kind:
	$(MAKE) -C backend/kind deps up-if-not-exists kubeconfig

.PHONY: dind
dind: clean buildir
	$(MAKE) -C backend/kind deps up kubeconfig docker-kubeconfig prepare
	$(MAKE) scf

# catapult-only targets:

.PHONY: catapult-test
catapult-test:
	$(MAKE) -C tests

.PHONY: catapult-lint
catapult-lint:
	$(MAKE) -C tests lint

.PHONY: catapult-image
catapult-image:
	scripts/image.sh

# extra targets:
.PHONY: module-extra-concourse
module-extra-concourse:
	$(MAKE) -C modules/extra concourse

.PHONY: module-extra-ingress
module-extra-ingress:
	$(MAKE) -C modules/extra ingress

.PHONY: module-extra-ingress-forward
module-extra-ingress-forward:
	$(MAKE) -C modules/extra ingress-forward

.PHONY: module-extra-kwt
module-extra-kwt:
	$(MAKE) -C modules/extra kwt

.PHONY: module-extra-kwt-connect
module-extra-kwt-connect:
	$(MAKE) -C modules/extra kwt-connect

.PHONY: module-extra-log
module-extra-log:
	$(MAKE) -C modules/extra log

.PHONY: module-extra-task
module-extra-task:
	$(MAKE) -C modules/extra task

.PHONY: module-extra-terminal
module-extra-terminal:
	$(MAKE) -C modules/extra terminal

.PHONY: module-extra-catapult-web
module-extra-catapult-web:
	$(MAKE) -C modules/extra web

.PHONY: module-extra-registry
module-extra-registry:
	$(MAKE) -C modules/extra registry

.PHONY: module-extra-brats-setup
module-extra-brats-setup:
	$(MAKE) -C modules/scf scf-brats-setup

## Experimental
.PHONY: module-experimental-eirinifs
module-experimental-eirinifs:
	$(MAKE) -C modules/experimental eirinifs

.PHONY: module-experimental-eirini_release
module-experimental-eirini_release:
	$(MAKE) -C modules/experimental eirini_release

# scf-only targets:
.PHONY: scf-deploy
scf-deploy: clean buildir
	$(MAKE) k8s kubeconfig scf

.PHONY: scf-clean
scf-clean:
	$(MAKE) -C modules/scf clean

.PHONY: scf
scf:
	$(MAKE) -C modules/scf

.PHONY: scf-login
scf-login:
	$(MAKE) -C modules/scf login

.PHONY: scf-gen-config
scf-gen-config:
	$(MAKE) -C modules/scf gen-config

.PHONY: scf-install
scf-install:
	$(MAKE) -C modules/scf install

.PHONY: scf-upgrade
scf-upgrade:
	$(MAKE) -C modules/scf upgrade

.PHONY: scf-chart
scf-chart:
	$(MAKE) -C modules/common
	$(MAKE) -C modules/scf chart

.PHONY: scf-build
scf-build:
	$(MAKE) -C modules/scf build-scf-from-source
	$(MAKE) scf-gen-config
	$(MAKE) -C modules/scf install

.PHONY: scf-purge
scf-purge:
	$(MAKE) -C modules/scf purge

.PHONY: scf-build-stemcell
scf-build-stemcell:
	$(MAKE) -C modules/scf stemcell_build

# stratos-only targets:
.PHONY: stratos
stratos:
	$(MAKE) -C modules/stratos

.PHONY: stratos-clean
stratos-clean:
	$(MAKE) -C modules/stratos clean

.PHONY: stratos-chart
stratos-chart:
	$(MAKE) -C modules/stratos chart

.PHONY: stratos-gen-config
stratos-gen-config:
	$(MAKE) -C modules/stratos gen-config

.PHONY: stratos-install
stratos-install:
	$(MAKE) -C modules/stratos install

.PHONY: stratos-upgrade
stratos-upgrade:
	$(MAKE) -C modules/stratos upgrade

# metrics-only targets:
.PHONY: metrics
metrics:
	$(MAKE) -C modules/metrics

.PHONY: metrics-clean
metrics-clean:
	$(MAKE) -C modules/metrics clean

.PHONY: metrics-chart
metrics-chart:
	$(MAKE) -C modules/metrics chart

.PHONY: metrics-gen-config
metrics-gen-config:
	$(MAKE) -C modules/metrics gen-config

.PHONY: metrics-upgrade
metrics-upgrade:
	$(MAKE) -C modules/metrics upgrade

# test-only targets:
.PHONY: tests
tests:
	$(MAKE) -C modules/tests

.PHONY: tests-smoke
tests-smoke:
	$(MAKE) -C modules/tests smoke

.PHONY: tests-smoke-kube
tests-smoke-kube:
	$(MAKE) -C modules/tests smoke-kube

.PHONY: tests-kubecats
tests-kubecats:
	$(MAKE) -C modules/tests kubecats

.PHONY: tests-brats
tests-brats:
	$(MAKE) -C modules/tests brats

.PHONY: tests-eirini-persi
tests-eirini-persi:
	$(MAKE) -C modules/tests test-eirini-persi

.PHONY: tests-smoke-scf
tests-smoke-scf:
	$(MAKE) -C modules/tests smoke-scf

.PHONY: tests-cats
tests-cats:
	$(MAKE) -C modules/tests cats

# Samples and fixtures
.PHONY: sample
sample:
	$(MAKE) -C modules/tests sample

.PHONY: sample-ticking
sample-ticking:
	$(MAKE) -C modules/tests sample-ticking

# Deprecated targets:

.PHONY: kind
kind::
	@echo 'WARNING: target deprecated. Please use `make k8s` or `BACKEND=kind make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
kind:: clean buildir
	$(MAKE) -C backend/kind
	$(MAKE) kubeconfig

.PHONY: gke
gke::
	@echo 'WARNING: target deprecated. Please use `BACKEND=gke make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
gke:: clean buildir
	$(MAKE) -C backend/gke

.PHONY: eks
eks::
	@echo 'WARNING: target deprecated. Please use "BACKEND=eks make k8s" instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
eks:: clean buildir
	$(MAKE) -C backend/eks

.PHONY: minikube
minikube::
	@echo 'WARNING: target deprecated. Please use "BACKEND=minikube make k8s" instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
minikube:: clean buildir
	$(MAKE) -C backend/minikube

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
	$(MAKE) -C backend/caasp4os clean

.PHONY: caasp4os
caasp4os::
	@echo 'WARNING: target deprecated. Please use `BACKEND=caasp4os make k8s` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
caasp4os:: caasp4os-clean buildir
	$(MAKE) -C backend/caasp4os

.PHONY:image
image::
	@echo 'WARNING: target deprecated. Please use `make catapult-image` instead.'
	@echo 'Kindly waiting for 20s…'; sleep 20
image:: catapult-image
