.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: deploy
deploy:
	./deploy.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: all
all: deps deploy
