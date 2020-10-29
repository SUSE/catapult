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

.PHONY: up
up:
	./up.sh

.PHONY: all
all: deps up

# one-offs:

.PHONY: start
start:
	./start.sh

.PHONY: stop
stop:
	./stop.sh
