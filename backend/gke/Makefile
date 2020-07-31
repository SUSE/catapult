.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: tfsetup
tfsetup:
	./tfsetup.sh

.PHONY: clean
clean: tfsetup
	./clean.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: deploy
deploy: tfsetup
	./deploy.sh

.PHONY: all
all: deps deploy
