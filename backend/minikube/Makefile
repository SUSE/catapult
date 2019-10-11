.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	# No-op

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps-minikube
deps-minikube:
	./deps.sh

.PHONY: up-minikube
up-minikube:
	./up.sh

.PHONY: prepare-minikube
prepare-minikube:
	./prepare.sh

.PHONY: all
all: deps-minikube up-minikube prepare-minikube

# one-offs:

.PHONY: start-minikube
start-minikube:
	./start.sh

.PHONY: stop-minikube
stop-minikube:
	./stop.sh
