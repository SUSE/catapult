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

.PHONY: all
all: deploy
