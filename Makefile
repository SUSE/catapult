.PHONY: setup
setup:
	scripts/setup.sh

.PHONY: deps
deps:
	scripts/tools.sh

.PHONY: clean
clean:
	scripts/clean.sh

.PHONY: up
up:
	scripts/up.sh

.PHONY: gen-config
gen-config:
	scripts/gen_scf_config.sh

.PHONY: scf
scf:
	scripts/setup_scf.sh

.PHONY: chart
chart:
	scripts/chart.sh

.PHONY: all
all: clean deps up gen-config chart setup scf