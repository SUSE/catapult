.PHONY: buildir
buildir:
	scripts/buildir.sh

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

.PHONY: start
start:
	scripts/kind_start.sh

.PHONY: stop
stop:
	scripts/kind_stop.sh

# scf-only targets:

.PHONY: setup
setup:
	scripts/scf_setup.sh

.PHONY: restart
restart:
	scripts/restart.sh

.PHONY: gen-config
gen-config:
	scripts/scf_gen_config.sh

.PHONY: chart
chart:
	scripts/scf_chart.sh

.PHONY: scf
scf:
	scripts/scf_install.sh

.PHONY: login
login:
	scripts/scf_login.sh

.PHONY: upgrade
upgrade:
	scripts/scf_upgrade.sh

.PHONY: clean-scf
clean-scf:
	scripts/scf_clean.sh

.PHONY: build-scf-from-source
build-scf-from-source:
	scripts/scf_build.sh

# stratos-only targets:

.PHONY: stratos
stratos:
	scripts/stratos.sh

# test-only targets:

.PHONY: smoke
smoke:
	scripts/tests_smoke.sh

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

.PHONY: deps-caasp4os
deps-caasp4os: buildir
	scripts/docker_skuba.sh

.PHONY: caasp4os-deploy
caasp4os-deploy:
	scripts/caasp4os_deploy.sh

.PHONY: caasp-prepare
caasp-prepare:
	scripts/caasp_prepare.sh

.PHONY: clean-caasp4os
clean-caasp4os:
	scripts/caasp4os_destroy.sh

# full targets:

.PHONY: kind
kind: clean deps-kind up kubeconfig

.PHONY: all
all: kind setup chart gen-config scf login

.PHONY: dind
dind: kind docker-kubeconfig setup chart gen-config scf login

.PHONY: all-caasp4os
all-caasp4os: deps-caasp4os caasp4os-deploy caasp-prepare chart gen-config scf login
