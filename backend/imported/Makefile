.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: check
check:
	./check.sh

.PHONY: all
all: deps kubeconfig check
