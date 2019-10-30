.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	# No-op

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: up
up:
	./up.sh

.PHONY: prepare
prepare:
	./prepare.sh

.PHONY: all
all: deps up prepare

# one-offs:

.PHONY: start
start:
	./start.sh

.PHONY: stop
stop:
	./stop.sh
