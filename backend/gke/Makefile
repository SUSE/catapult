.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: tfsetup
tfsetup:
	./tfsetup.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: clean
clean: deps tfsetup
	./clean.sh

.PHONY: deploy
deploy: deps tfsetup
	./deploy.sh

.PHONY: find-resources
find-resources:
	./$@.sh

.PHONY: force-clean-cluster
force-clean-cluster:
	./$@.sh

.PHONY: all
all: deploy

.PHONY: airgap-up
airgap-up:
	./airgap-up.sh

.PHONY: airgap-down
airgap-down:
	./airgap-down.sh
