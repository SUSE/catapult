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

.PHONY: start
start:
	scripts/start.sh

.PHONY: stop
stop:
	scripts/stop.sh

.PHONY: gen-config
gen-config:
	scripts/gen_scf_config.sh

.PHONY: scf
scf:
	scripts/install_scf.sh

.PHONY: chart
chart:
	scripts/chart.sh

.PHONY: login
login:
	scripts/login.sh

.PHONY: stratos
stratos:
	scripts/stratos.sh

.PHONY: kind
kind: clean deps up

.PHONY: all
all: kind gen-config chart setup scf login

.PHONY: build-scf-from-source
build-scf-from-source:
	scripts/build_scf.sh

.PHONY: build-stemcell-from-source
build-stemcell-from-source:
	scripts/build_stemcell.sh
