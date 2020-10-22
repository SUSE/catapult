ifneq ($(DEBUG_MODE),true)
	MAKE=make -s
endif

# NOTE: BACKEND is dup in include/common.sh to allow BACKEND override when loading from json config files
export BACKEND?=kind
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

.PHONY: common-deps
common-deps: ##@STATES Install common deps kubectl, yq, yamlpatch, and helm into BUILD_DIR
common-deps: buildir
	$(MAKE) -C modules/common

# General targets (Public)
.PHONY: clean
clean: ##@STATES Delete cluster of type $BACKEND and location build$CLUSTER_NAME
clean: kubecf-clean # first kubecf-clean to delete PVCs, DNS entries, etc
	$(MAKE) -C backend/$(BACKEND) clean

.PHONY: k8s
k8s: ##@STATES Delete if exists then deploy cluster of type $BACKEND in build$CLUSTER_NAME
k8s: clean common-deps
	$(MAKE) -C backend/$(BACKEND)

.PHONY: kubeconfig
kubeconfig: ##@STATES Import cluster of type $BACKEND from $KUBECFG in build$CLUSTER_NAME
kubeconfig: common-deps
	$(MAKE) -C backend/$(BACKEND) deps
	$(MAKE) -C backend/$(BACKEND) kubeconfig
	backend/check.sh

.PHONY: start
start: ##@k8s Start cluster of type $BACKEND (only present in some backends, like kind)
	$(MAKE) -C backend/$(BACKEND) start

.PHONY: stop
stop: ##@k8s Stop cluster of type $BACKEND (only present in some backends, like kind)
	$(MAKE) -C backend/$(BACKEND) stop

.PHONY: restart
restart: ##@k8s Restart cluster of type $BACKEND (only present in some backends, like kind)
	$(MAKE) -C backend/$(BACKEND) restart

.PHONY: recover
recover: ##@k8s Obtain kubeconfig from cluster without build folder (only present in kind)
recover: common-deps
	$(MAKE) -C modules/common
	$(MAKE) -C backend/$(BACKEND) kubeconfig

.PHONY: force-clean
force-clean: ##@k8s Remove build folder no matter what (caution)
force-clean: buildir clean

.PHONY: find-resources
find-resources: ##@k8s List used and unused resources of type $BACKEND (only present in some backends)
find-resources:
	$(MAKE) -C backend/$(BACKEND) $@

.PHONE: force-clean-cluster
force-clean-cluster: ##@k8s Force delete a previously unmanaged cluster (only present in some backends)
force-clean-cluster:
	$(MAKE) -C backend/$(BACKEND) $@

.PHONY: all
all: ## Alias for `make k8s scf scf-login`
all: k8s kubecf kubecf-login # TODO remove scf-deploy

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
catapult-test: ##@catapult Run linters, unit & integration tests of catapult
	$(MAKE) -C tests

.PHONY: catapult-lint
catapult-lint: ##@catapult Only run linters
	$(MAKE) -C tests lint

.PHONY: catapult-image
catapult-image: ##@catapult Build catapult docker image
	scripts/image.sh

# extra targets:
.PHONY: module-extra-top
module-extra-top: ##@module-extra Install k9s in buildfoo/bin/
	$(MAKE) -C modules/extra top

.PHONY: module-extra-task
module-extra-task: ##@module-extra Run task script inside task pod in catapult ns
	$(MAKE) -C modules/extra task

.PHONY: module-extra-terminal
module-extra-terminal: ##@module-extra Start a pod with catapult installed inside and open a shell in it
	$(MAKE) -C modules/extra terminal

.PHONY: module-extra-catapult-web
module-extra-catapult-web: ##@module-extra Start docker image in host with a web tty. Useful after calling module-extra-terminal
	$(MAKE) -C modules/extra web

.PHONY: module-extra-registry
module-extra-registry: ##@module-extra Inject host registry intro cluster workers
	$(MAKE) -C modules/extra registry

.PHONY: module-extra-concourse
module-extra-concourse: ##@module-extra Deploy concourse instance in cluster
	$(MAKE) -C modules/extra concourse

.PHONY: module-extra-drone
module-extra-drone: ##@module-extra Deploy drone instance in cluster
	$(MAKE) -C modules/extra drone

.PHONY: module-extra-gitea
module-extra-gitea: ##@module-extra Deploy gitea instance in cluster
	$(MAKE) -C modules/extra gitea

.PHONY: module-extra-ingress
module-extra-ingress: ##@module-extra Start socksproxy pod
	$(MAKE) -C modules/extra ingress

.PHONY: module-extra-ingress-forward
module-extra-ingress-forward: ##@module-extra Port-forward socksproxy pod to :8000
	$(MAKE) -C modules/extra ingress-forward

.PHONY: module-extra-kwt
module-extra-kwt:
	$(MAKE) -C modules/extra kwt

.PHONY: module-extra-fissile
module-extra-fissile:
	$(MAKE) -C modules/extra fissile

.PHONY: module-extra-kwt-connect
module-extra-kwt-connect:
	$(MAKE) -C modules/extra kwt-connect

.PHONY: module-extra-log
module-extra-log:
	$(MAKE) -C modules/extra log

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

.PHONY: module-experimental-airgap-up
module-experimental-airgap-up:
	$(MAKE) -C modules/experimental airgap-up

.PHONY: module-experimental-airgap-down
module-experimental-airgap-down:
	$(MAKE) -C modules/experimental airgap-down

.PHONY: module-experimental-tf-force-clean
module-experimental-tf-force-clean:
	$(MAKE) -C modules/experimental tf_force_clean

.PHONY: module-experimental-tf-auto-deploy
module-experimental-tf-auto-deploy:
	$(MAKE) -C modules/experimental tf_auto_deploy

# kubecf-only targets:
.PHONY: kubecf-build
kubecf-build: ##@kubecf Build chart from source and install KubeCF
	$(MAKE) -C modules/kubecf build-from-source
	$(MAKE) kubecf-gen-config
	$(MAKE) -C modules/kubecf install

.PHONY: kubecf-clean
kubecf-clean: ##@kubecf Only delete installation of KubeCF & related files
	$(MAKE) -C modules/kubecf clean

.PHONY: kubecf
kubecf: ##@STATES Delete if exists then deploy KubeCF in cluster
	$(MAKE) -C modules/kubecf

.PHONY: kubecf-chart
kubecf-chart: ##@kubecf Only obtain KubeCF chart, by file or download
	$(MAKE) -C modules/kubecf chart

.PHONY: kubecf-gen-config
kubecf-gen-config: ##@kubecf Only generate KubeCF config yamls
	$(MAKE) -C modules/kubecf gen-config

.PHONY: kubecf-install
kubecf-install: ##@kubecf Only install KubeCF
	$(MAKE) -C modules/kubecf install

.PHONY: kubecf-upgrade
kubecf-upgrade: ##@kubecf Only upgrade KubeCF
	$(MAKE) -C modules/kubecf upgrade

.PHONY: kubecf-login
kubecf-login: ##@kubecf Only perform cf login against deployed KubeCF
	$(MAKE) -C modules/kubecf login

.PHONY: kubecf-minibroker
kubecf-minibroker: ##@kubecf Deploy minibroker & services on KubeCF
	$(MAKE) -C modules/kubecf minibroker

.PHONY: kubecf-purge
kubecf-purge: ##@kubecf Purge all apps, buildpacks and services from KubeCF
	$(MAKE) -C modules/kubecf purge

.PHONY: kubecf-build-stemcell
kubecf-build-stemcell: ##@kubecf Build stemcell for KubeCF
	$(MAKE) -C modules/kubecf stemcell_build

.PHONY: kubecf-klog
kubecf-klog: ##@kubecf Retrieve and run klog.sh
	$(MAKE) -C modules/kubecf klog

# scf-only targets:

# Provide compatibility with kubecf by redirecting:
#    SCF_OPERATOR=true make scf*
# to:
#    make kubecf
ifeq "$(SCF_OPERATOR)" "true"
scf-build: kubecf-build
scf-clean: kubecf-clean
scf: kubecf
scf-chart: kubecf-chart
scf-gen-config: kubecf-gen-config
scf-install: kubecf-install
scf-upgrade: kubecf-upgrade
scf-login: kubecf-login
scf-minibroker: kubecf-minibroker
scf-purge: kubecf-purge
scf-build-stemcell: kubecf-build-stemcell
scf-klog: kubecf-klog
else
.PHONY: scf-build
scf-build: ##@scf Build chart from source and install CF
	$(MAKE) -C modules/scf build-scf-from-source
	$(MAKE) scf-gen-config
	$(MAKE) -C modules/scf install

.PHONY: scf-clean
scf-clean: ##@scf Only delete installation of CF & related files
	$(MAKE) -C modules/scf clean

.PHONY: scf
scf: ##@STATES Delete if exists then deploy CF in cluster
	$(MAKE) -C modules/scf

.PHONY: scf-chart
scf-chart: ##@scf Only obtain CF chart, by file or download
	$(MAKE) -C modules/scf chart

.PHONY: scf-gen-config
scf-gen-config: ##@scf Only generate CF config yamls
	$(MAKE) -C modules/scf gen-config

.PHONY: scf-install
scf-install: ##@scf Only install CF
	$(MAKE) -C modules/scf install

.PHONY: scf-upgrade
scf-upgrade: ##@scf Only upgrade CF
	$(MAKE) -C modules/scf upgrade

.PHONY: scf-login
scf-login: ##@scf Only perform cf login against deployed CF
	$(MAKE) -C modules/scf login

.PHONY: scf-minibroker
scf-minibroker: ##@scf Deploy minibroker & services on CF
	$(MAKE) -C modules/scf minibroker

.PHONY: scf-purge
scf-purge: ##@scf Purge all apps, buildpacks and services from CF
	$(MAKE) -C modules/scf purge

.PHONY: scf-build-stemcell
scf-build-stemcell: ##@scf Build stemcell
	$(MAKE) -C modules/scf stemcell_build

.PHONY: scf-klog
scf-klog: ##@scf retreive and run klog.sh
	$(MAKE) -C modules/scf scf-klog
endif

# stratos-only targets:
.PHONY: stratos
stratos: ##@STATES Delete if exists then deploy Stratos console
	$(MAKE) -C modules/stratos

.PHONY: stratos-clean
stratos-clean: ##@stratos Remove Stratos console
	$(MAKE) -C modules/stratos clean

.PHONY: stratos-chart
stratos-chart: ##@stratos Only obtain Stratos console chart, by file or download
	$(MAKE) -C modules/stratos chart

.PHONY: stratos-gen-config
stratos-gen-config: ##@stratos Only generate Stratos console config yamls
	$(MAKE) -C modules/stratos gen-config

.PHONY: stratos-install
stratos-install: ##@stratos Only install Stratos console
	$(MAKE) -C modules/stratos install

.PHONY: stratos-upgrade
stratos-upgrade: ##@stratos Only upgrade Stratos console
	$(MAKE) -C modules/stratos upgrade

.PHONY: stratos-reachable
stratos-reachable: ##@stratos Do a simple check if the stratos UI is reachable
	$(MAKE) -C modules/stratos reachable

# metrics-only targets:
.PHONY: metrics
metrics: ##@STATES Delete if exists then deploy Stratos metrics
	$(MAKE) -C modules/metrics

.PHONY: metrics-clean
metrics-clean: ##@metrics Remove Stratos metrics
	$(MAKE) -C modules/metrics clean

.PHONY: metrics-chart
metrics-chart: ##@metrics Only obtain Stratos metrics chart, by file or download
	$(MAKE) -C modules/metrics chart

.PHONY: metrics-gen-config
metrics-gen-config: ##@metrics Only generate Stratos metrics config yamls
	$(MAKE) -C modules/metrics gen-config

.PHONY: metrics-install
metrics-install: ##@metrics Only install Stratos metrics
	$(MAKE) -C modules/metrics install

.PHONY: metrics-upgrade
metrics-upgrade: ##@metrics Only upgrade Stratos metrics
	$(MAKE) -C modules/metrics upgrade

# test-only targets:
.PHONY: tests
tests: ##@STATES Run a reliable subset of tests against CF
	$(MAKE) -C modules/tests

.PHONY: tests-kubecf
tests-kubecf: ##@tests Run specified KUBECF_TEST_SUITE
	$(MAKE) -C modules/tests kubecf

.PHONY: tests-smoke
tests-smoke: ##@tests Build and run scf Smokes from host
	$(MAKE) -C modules/tests smoke

.PHONY: tests-smoke-kube
tests-smoke-kube: ##@tests Build and run scf Smokes from pod
	$(MAKE) -C modules/tests smoke-kube

.PHONY: tests-kubecats
tests-kubecats: ##@tests Build and run scf CATS from pod
	$(MAKE) -C modules/tests kubecats

.PHONY: tests-brats
tests-brats: ##@tests Run scf BRATS
	$(MAKE) -C modules/tests brats

.PHONY: tests-eirini-persi
tests-eirini-persi:
	$(MAKE) -C modules/tests test-eirini-persi

.PHONY: tests-smoke-scf
tests-smoke-scf:
	$(MAKE) -C modules/tests smoke-scf

.PHONY: tests-cats
tests-cats: ##@tests Build and run scf CATS from host
	$(MAKE) -C modules/tests cats

.PHONY: tests-cats-scf
tests-cats-scf:
	$(MAKE) -C modules/tests cats-scf

.PHONY: tests-autoscaler
tests-autoscaler:
	$(MAKE) -C modules/tests autoscaler

.PHONY: tests-stress-benchmark
tests-stress-benchmark:
	$(MAKE) -C modules/tests stress-benchmark

# Samples and fixtures
.PHONY: sample
sample: ##@tests Deploy sample app
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

# Build help output from the makefile comments:
# - Comments after a target that start with '\#\#' will be taken
# - Comments can be added to a category with @category
# TODO choose a regex
HELP_FUNC = \
    %help; \
    while(<>) { push @{$$help{$$2 // 'other'}}, [$$1, $$3] if /^([a-zA-Z0-9\-]+)\s*:.*\#\#(?:@([a-zA-Z0-9\-]+))?\s(.*)$$/ }; \
    for (keys %help) { \
			if ($$_ !~ "states") { \
				print "$$_:\n"; \
				for (@{$$help{$$_}}) { \
					$$sep = " " x (30  - length $$_->[0]); \
					print "  $$_->[0]$$sep$$_->[1]\n"; \
				}; \
      } \
    print "\n"; }
HELP_STATES = \
    %help; \
    while(<>) { push @{$$help{$$2}}, [$$1, $$3] if /^([a-zA-Z0-9\-]+)\s*:.*\#\#\@(?:(STATES))?\s(.*)$$/ }; \
    for (keys %help) { \
			print "$$_:\n"; \
			for (@{$$help{$$_}}) { \
				$$sep = " " x (23  - length $$_->[0]); \
				print "  $$_->[0]$$sep$$_->[1]\n"; \
			}; \
    print "\n"; }

help: ##@other Show help
	@echo 'USAGE: <envvars> make [target]'
	@echo
	@echo '  Main state targets and their cleaning targets:	'
	@echo
	@echo '     {} ─┬─> k8s        ─┬─> kubecf ────> tests ────> stratos ────> metrics	'
	@echo '         └─> kubeconfig ─┘																								'
	@echo
	@echo '             clean           kubecf-clean           stratos-clean   metrics-clean'
	@echo
	@echo '  Calling `make k8s` creates a buildfoo folder on catapult/'
	@echo '  All states operate against the files in that buildfoo folder'
	@echo '  Calling `make clean` deletes the cluster and then the buildfoo folder'
	@echo
	@perl -e '$(HELP_STATES)' $(MAKEFILE_LIST)
	@echo
	@echo 'OPTIONS:'
	@echo '  Passed as env vars. Them and their default values are sourced from:'
	@echo '    (in descendent order of priority)'
	@echo '    backend/foo/defaults.sh  (if doing make k8s or make kubeconfig)'
	@echo '    modules/foo/defaults.sh								'
	@echo '    include/defaults_global{,_private}.sh'
	@echo '    modules/common/defaults.sh						'
	@echo
	@echo '  BACKEND option is mandatory. Is the type of k8s cluster to create/target. Defaults to "kind"'
	@echo '  CLUSTER_NAME option specifies the name of the "buildCLUSTER_NAME". Defaults to "BACKEND"'
	@echo
	@echo '  A concatenated list of all options is compiled in buildfoo/defaults.sh on '
	@echo '  cluster creation.'
	@echo
	@echo 'EXAMPLES:'
	@echo '  Deploy a kind cluster, then KubeCF on top. Result in `buildkind` folder'
	@echo '  > make k8s kubecf'
	@echo
	@echo '  Deploy an EKS cluster, then KubeCF, then stratos. Result in `buildeks` folder'
	@echo '  > BACKEND=eks make k8s kubecf stratos'
	@echo
	@echo '  Target the cluster `eks` manually'
	@echo '  > cd buildeks; source .envrc; kubectl get pods -A'
	@echo
	@echo '  Remove cluster `my_cluster`, then delete `buildmy_cluster` folder'
	@echo '  > BACKEND=my_cluster make clean'
	@echo
	@echo '  Import existing cluster kubeconfig by creating a `buildfoo` folder'
	@echo '   BACKEND=imported CLUSTER_NAME=foo KUBECFG=/tmp/kubeconfig make k8s'
	@echo
	@echo 'For more info, see make help-all.'


help-all: help
help-all: ##@other Show all help
	@echo
	@echo 'SUBSTATES and other targets:'
	@echo
	@perl -e '$(HELP_FUNC)' $(MAKEFILE_LIST)
	@echo
