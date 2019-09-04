.PHONY: buildir
buildir:
	scripts/buildir.sh

.PHONY: setup
setup:
	scripts/scf_setup.sh

.PHONY: deps
deps: buildir
	scripts/kind_tools.sh

.PHONY: clean
clean:
	scripts/kind_clean.sh

.PHONY: up
up:
	scripts/kind_up.sh

.PHONY: start
start:
	scripts/kind_start.sh

.PHONY: stop
stop:
	scripts/kind_stop.sh

.PHONY: gen-config
gen-config:
	scripts/scf_gen_config.sh

.PHONY: scf
scf:
	scripts/scf_install.sh

.PHONY: chart
chart:
	scripts/scf_chart.sh

.PHONY: login
login:
	scripts/scf_login.sh

.PHONY: stratos
stratos:
	scripts/stratos.sh

.PHONY: upgrade
upgrade:
	scripts/scf_upgrade.sh

.PHONY: smoke
smoke:
	scripts/tests_smoke.sh

.PHONY: cats
cats:
	scripts/tests_cats.sh

.PHONY: kind
kind: clean deps up kubeconfig

.PHONY: all
all: kind setup chart gen-config scf login

.PHONY: dind
dind: kind docker-kubeconfig setup chart gen-config scf login

.PHONY: clean-scf
clean-scf:
	scripts/scf_clean.sh

.PHONY: build-scf-from-source
build-scf-from-source:
	scripts/scf_build.sh

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
	scripts/ingress_forward.sh

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
all-caasp4os: deps-caasp4os caasp4os-deploy caasp-prepare chart gen-config scf login

.PHONY: clean-caasp4os
clean-caasp4os:
	scripts/caasp4os_destroy.sh

.PHONY: eirini-release
eirini-release:
	scripts/eirini_release.sh
