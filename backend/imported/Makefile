.DEFAULT_GOAL := all

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps
deps:
	#no-op

.PHONY: find-resources
find-resources:
	echo "$@ does not make sense for ${BACKEND}; skipped"

.PHONY: force-clean-cluster
force-clean-cluster:
	echo "$@ does not make sense for ${BACKEND}; skipped"

.PHONY: all
all: kubeconfig
