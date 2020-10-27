.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: tfsetup
tfsetup:
	./tfsetup.sh

.PHONY: deploy
deploy: deps tfsetup
	./deploy.sh

.PHONY: clean
clean: deps tfsetup
	./clean.sh

.PHONY: find-resources
find-resources:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: force-clean-cluster
force-clean-cluster:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: all
all: deploy
