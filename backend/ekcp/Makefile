.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: up
up:
	./up.sh

.PHONY: kubeconfig
kubeconfig:
	./kubeconfig.sh

.PHONY: deps
deps:
	# no-op

.PHONY: prepare
prepare:
	./prepare.sh

#.PHONY: prepare
#prepare:
#	make -C ../kind prepare

.PHONY: find-resources
find-resources:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: force-clean-cluster
force-clean-cluster:
	echo "$@ not implemented yet for ${BACKEND}"
	exit 1

.PHONY: all
all: up kubeconfig prepare
