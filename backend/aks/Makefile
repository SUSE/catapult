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
deploy: tfsetup
	./deploy.sh

.PHONY: clean
clean: tfsetup
	./clean.sh

.PHONY: all
all::
	@echo 'WARNING: stil WIP. Use it on your own risk.'
	@echo 'Kindly waiting for 5s…'; sleep 5
all:: deps deploy
