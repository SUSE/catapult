.PHONY: buildir
buildir:
	scripts/buildir.sh

# catapult-only targets:

.PHONY: catapult-test
catapult-test:
	scripts/tests_catapult.sh

.PHONY: catapult-web
catapult-web:
	scripts/web.sh

# kind-only targets:

.PHONY: deps-kind
deps-kind: buildir
	scripts/kind_tools.sh

.PHONY: clean
clean:
	scripts/kind_clean.sh

.PHONY: up
up:
	scripts/kind_up.sh

.PHONY: up_if_not_exists
up-if-not-exists:
	scripts/kind_up_if_not_exists.sh

.PHONY: start
start:
	scripts/kind_start.sh

.PHONY: stop
stop:
	scripts/kind_stop.sh

.PHONY: setup
setup:
	scripts/kind_setup.sh

# gke-only targets:

.PHONY: clean-gke
clean-gke:
	make -C scripts/gke clean

.PHONY: gke
gke: clean-gke buildir
	make -C scripts/gke

# minikube-only targets:

.PHONY: deps-minikube
deps-minikube: buildir
	scripts/minikube_deps.sh

.PHONY: clean-minikube
clean-minikube:
	scripts/minikube_clean.sh

.PHONY: up-minikube
up-minikube:
	scripts/minikube_up.sh

.PHONY: start-minikube
start-minikube:
	scripts/minikube_start.sh

.PHONY: stop-minikube
stop-minikube:
	scripts/minikube_stop.sh

.PHONY: prepare-minikube
prepare-minikube:
	scripts/minikube_prepare.sh

.PHONY: minikube
minikube: clean-minikube deps-minikube up-minikube prepare-minikube

.PHONY: task
task:
	scripts/task.sh

.PHONY: terminal
terminal:
	scripts/terminal.sh

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
	scripts/stratos.sh

.PHONY: clean-stratos
clean-stratos:
	scripts/stratos_clean.sh

# test-only targets:

.PHONY: smoke
smoke:
	scripts/tests_smoke.sh

.PHONY: smoke-kube
smoke-kube:
	scripts/tests_kubesmokes.sh

.PHONY: kubecats
kubecats:
	scripts/tests_kubecats.sh

.PHONY: brats
brats:
	scripts/tests_brats.sh

.PHONY: test-eirini-persi
test-eirini-persi:
	scripts/tests_eirini_persi.sh

.PHONY: smoke-scf
smoke-scf:
	scripts/tests_smoke_scf.sh

.PHONY: cats
cats:
	scripts/tests_cats.sh

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
	scripts/kubeconfig.sh

.PHONY: recover
recover: buildir kubeconfig

.PHONY: force-clean
force-clean: buildir clean

.PHONY:registry
registry:
	scripts/registry.sh

.PHONY:kwt
kwt:
	scripts/kwt.sh

.PHONY:kwt-connect
kwt-connect:
	scripts/kwt_connect.sh


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

# ingress-only targets:

.PHONY: ingress
ingress:
	scripts/ingress.sh

.PHONY: ingress-forward
ingress-forward:
	scripts/ingress_forward.sh

# caasp-only targets:

.PHONY: clean-caasp4os
clean-caasp4os:
	make -C scripts/caasp4os clean

.PHONY: caasp4os
caasp4os: clean-caasp4os buildir
	make -C scripts/caasp4os

# full targets:

.PHONY: kind
kind: clean deps-kind up kubeconfig

.PHONY: recover-or-kind
recover-or-kind: deps-kind up-if-not-exists kubeconfig

.PHONY: all
all: kind setup chart gen-config scf login

.PHONY: dind
dind: kind docker-kubeconfig setup chart gen-config scf login

.PHONY: all-minikube
all-minikube: minikube chart gen-config scf login

.PHONY: all-caasp4os
all-caasp4os: deps-caasp4os caasp4os-deploy caasp-prepare chart gen-config scf login

.PHONY: all-gke
all-gke: gke chart gen-config scf terminal
