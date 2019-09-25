.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	# No-op

.PHONY: deps-eks
deps-eks:
	./deps.sh

.PHONY: eks-deploy
eks-deploy:
	./deploy.sh

.PHONY: eks-prepare
eks-prepare:
	./prepare.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: all
all: clean deps-eks eks-deploy eks-prepare
