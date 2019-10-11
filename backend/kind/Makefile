.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps-kind
deps-kind:
	./deps.sh

.PHONY: up-kind
up-kind:
	./up.sh

.PHONY: kubeconfig-kind
kubeconfig-kind:
	./kubeconfig.sh

.PHONY: prepare-kind
prepare-kind:
	./prepare.sh

.PHONY: all
all: deps-kind up-kind kubeconfig-kind prepare-kind

# one-offs:

.PHONY: up_if_not_exists
up-if-not-exists:
	./up_if_not_exists.sh

.PHONY: start-kind
start-kind:
	./start.sh

.PHONY: stop
stop-kind:
	./stop.sh

.PHONY: restart-kind
restart-kind:
	./restart.sh
