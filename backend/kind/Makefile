.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps
deps:
	./deps.sh

.PHONY: up
up:
	./up.sh

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: docker-kubeconfig
docker-kubeconfig:
	./docker_kubeconfig.sh

.PHONY: prepare
prepare:
	./prepare.sh

.PHONY: find-resources
find-resources:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: force-clean-cluster
force-clean-cluster:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: all
all: deps up kubeconfig prepare

# one-offs:

.PHONY: up_if_not_exists
up-if-not-exists:
	./up_if_not_exists.sh

.PHONY: start
start:
	./start.sh

.PHONY: stop
stop:
	./stop.sh

.PHONY: restart
restart:
	./restart.sh
