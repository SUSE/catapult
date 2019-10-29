.DEFAULT_GOAL := all

.PHONY: tests-catapult-integration
tests-catapult-integration:
	./tests_catapult_integration.sh

.PHONY: tests-catapult
tests-catapult:
	./tests_catapult.sh

.PHONY: lint
lint:
	./lint.sh

.PHONY: all
all: lint tests-catapult tests-catapult-integration
