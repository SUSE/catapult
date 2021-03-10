.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: clean
clean:
	./destroy.sh

.PHONY: deps
deps:
	# no-op

.PHONY: deps-caasp4os
deps-caasp4os:
	./docker_skuba.sh

.PHONY: caasp4os-deploy
caasp4os-deploy:
	./deploy.sh

.PHONY: caasp-prepare
caasp-prepare:
	./prepare.sh

.PHONY: find-resources
find-resources:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: force-clean-cluster
force-clean-cluster:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: all
all: deps-caasp4os caasp4os-deploy caasp-prepare

.PHONY: airgap-up airgap-down
airgap-up airgap-down:
	echo "Not implemented yet" && exit 1
