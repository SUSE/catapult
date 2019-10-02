.PHONY: buildir
buildir:
	scripts/buildir.sh

# catapult-only targets:

.PHONY: catapult-test
catapult-test:
	scripts/tests_catapult.sh

# kind-only targets:

.PHONY: clean-kind
clean-kind:
	make -C scripts/kind clean

.PHONY: kind
kind: clean-kind buildir
	make -C scripts/kind
	make kubeconfig

.PHONY: up_if_not_exists
up-if-not-exists:
	make -C scripts/kind up_if_not_exists

.PHONY: start-kind
start-kind:
	make -C scripts/kind start

.PHONY: stop-kind
stop-kind:
	make -C scripts/kind stop

.PHONY: restart-kind
restart-kind:
	make -C scripts/kind restart

# gke-only targets:

.PHONY: clean-gke
clean-gke:
	make -C scripts/gke clean

.PHONY: gke
gke: clean-gke buildir
	make -C scripts/gke

# minikube-only targets:

.PHONY: clean-minikube
clean-minikube:
	make -C scripts/minikube clean

.PHONY: minikube
minikube: clean-minikube buildir
	make -C scripts/minikube

# extra targets:

.PHONY: ingress
ingress:
	make -C scripts/extra ingress

.PHONY: ingress-forward
ingress-forward:
	make -C scripts/extra ingress-forward

.PHONY: kwt
kwt:
	make -C scripts/extra kwt

.PHONY: kwt-connect
kwt-connect:
	make -C scripts/extra kwt-connect

.PHONY: task
task:
	make -C scripts/extra task

.PHONY: terminal
terminal:
	make -C scripts/extra terminal

.PHONY: catapult-web
catapult-web:
	make -C scripts/extra catapult-web

# scf-only targets:

.PHONY: clean-scf
clean-scf:
	make -C scripts/scf clean

.PHONY: scf
scf:
	make -C scripts/scf

.PHONY: upgrade
upgrade:
	make -C scripts/scf upgrade

.PHONY: build-scf-from-source
build-scf-from-source:
	make -C scripts/scf build-scf-from-source

.PHONY: deploy-scf
deploy-scf: chart gen-config scf

# stratos-only targets:

.PHONY: stratos
stratos:
	make -C scripts/stratos

.PHONY: clean-stratos
clean-stratos:
	make -C scripts/stratos clean

# test-only targets:

.PHONY: tests
tests:
	make -C scripts/tests

.PHONY: tests-smoke
tests-smoke:
	make -C scripts/tests smoke

.PHONY: tests-smoke-kube
tests-smoke-kube:
	make -C scripts/tests smoke-kube

.PHONY: tests-kubecats
tests-kubecats:
	make -C scripts/tests kubecats

.PHONY: tests-brats
tests-brats:
	make -C scripts/tests brats

.PHONY: tests-eirini-persi
tests-eirini-persi:
	make -C scripts/tests test-eirini-persi

.PHONY: tests-smoke-scf
tests-smoke-scf:
	make -C scripts/tests smoke-scf

.PHONY: tests-cats
tests-cats:
	make -C scripts/tests cats

# one-off targets:

.PHONY: build-stemcell-from-source
build-stemcell-from-source:
	scripts/stemcell_build.sh

.PHONY: docker-kubeconfig
docker-kubeconfig:
	scripts/docker_kubeconfig.sh

.PHONY:image
image:
	scripts/image.sh

.PHONY: kubeconfig
kubeconfig:
	make -C scripts/kind kubeconfig-kind

.PHONY: recover
recover: buildir kubeconfig

.PHONY: force-clean
force-clean: buildir clean-kind

.PHONY:registry
registry:
	scripts/registry.sh

# Samples and fixtures

.PHONY: sample
sample:
	scripts/sample.sh

.PHONY: sample-ticking
sample-ticking:
	scripts/sample-ticking.sh

# eirini-only targets:

.PHONY:eirinifs
eirinifs:
	scripts/eirinifs.sh

.PHONY: eirini-release
eirini-release:
	scripts/eirini_release.sh

# caasp-only targets:

.PHONY: clean-caasp4os
clean-caasp4os:
	make -C scripts/caasp4os clean

.PHONY: caasp4os
caasp4os: clean-caasp4os buildir
	make -C scripts/caasp4os

# full targets:

.PHONY: recover-or-kind
recover-or-kind: deps-kind up-if-not-exists kubeconfig

.PHONY: all
all: kind scf

.PHONY: clean
clean: clean-kind

.PHONY: dind
dind: kind docker-kubeconfig scf

.PHONY: all-minikube
all-minikube: minikube scf

.PHONY: all-caasp4os
all-caasp4os: deps-caasp4os scf

.PHONY: all-gke
all-gke: gke scf terminal
