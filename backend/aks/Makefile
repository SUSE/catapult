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
all::
	@echo 'WARNING: stil WIP. Use it on your own risk.'
	@echo 'Kindly waiting for 5s…'; sleep 5
all:: deps deploy
