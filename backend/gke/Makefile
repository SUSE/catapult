.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: deps-gke
deps-gke:
	./deps.sh

.PHONY: deploy-gke
deploy-gke:
	./deploy.sh

.PHONY: all
all: deps-gke deploy-gke
