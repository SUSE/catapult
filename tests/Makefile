.DEFAULT_GOAL := all

.PHONY: integration-tests
integration-tests:
	./integration_tests.sh

.PHONY: unit-tests
unit-tests:
	./unit_tests.sh

.PHONY: lint
lint:
	./lint.sh

.PHONY: all
all: lint unit-tests integration-tests
