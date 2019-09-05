.PHONY: setup
setup:
	scripts/setup.sh

.PHONY: deps
deps:
	scripts/tools.sh

.PHONY: clean
clean:
	scripts/clean.sh

.PHONY: up
up:
	scripts/up.sh

.PHONY: start
start:
	scripts/start.sh

.PHONY: stop
stop:
	scripts/stop.sh

.PHONY: restart
restart:
	scripts/restart.sh

.PHONY: gen-config
gen-config:
	scripts/gen_scf_config.sh

.PHONY: scf
scf:
	scripts/install_scf.sh

.PHONY: chart
chart:
	scripts/chart.sh

.PHONY: login
login:
	scripts/login.sh

.PHONY: stratos
stratos:
	scripts/stratos.sh

.PHONY: upgrade
upgrade:
	scripts/upgrade.sh

.PHONY: smoke
smoke:
	scripts/smoke.sh

.PHONY: cats
cats:
	scripts/cats.sh

.PHONY: kind
kind: clean deps up kubeconfig

.PHONY: all
all: kind gen-config chart setup scf login

.PHONY: dind
dind: kind docker-kubeconfig gen-config chart setup scf login

.PHONY: clean-scf
clean-scf:
	scripts/scf_clean.sh

.PHONY: build-scf-from-source
build-scf-from-source:
	scripts/build_scf.sh

.PHONY: build-stemcell-from-source
build-stemcell-from-source:
	scripts/build_stemcell.sh

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
recover: deps kubeconfig

.PHONY: force-clean
force-clean: deps clean

.PHONY:registry
registry:
	scripts/registry.sh

.PHONY:eirinifs
eirinifs:
	scripts/eirinifs.sh

.PHONY: ingress
ingress:
	scripts/ingress.sh

.PHONY: ingress-forward
ingress-forward:
	scripts/ingress-forward.sh

.PHONY: deps-caasp4os
deps-caasp4os: deps
	scripts/docker_skuba.sh

.PHONY: caasp4os-deploy
caasp4os-deploy:
	scripts/caasp4os_deploy.sh

.PHONY: caasp-prepare
caasp-prepare:
	scripts/caasp_prepare.sh

.PHONY: all-caasp4os
all-caasp4os: deps-caasp4os caasp4os-deploy caasp-prepare gen-config chart scf login

.PHONY: clean-caasp4os
clean-caasp4os:
	scripts/caasp4os_destroy.sh

.PHONY: eirini-release
eirini-release:
	scripts/eirini-release.sh
