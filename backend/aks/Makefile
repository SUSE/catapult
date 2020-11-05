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
all::
	@echo 'WARNING: stil WIP. Use it on your own risk.'
	@echo 'Kindly waiting for 5s…'; sleep 5
all:: deploy

.PHONY: airgap-up airgap-down
airgap-up airgap-down:
	echo "Not implemented yet" && exit 1
