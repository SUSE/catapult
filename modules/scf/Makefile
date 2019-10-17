.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: chart
chart:
	./chart.sh

.PHONY: gen-config
gen-config:
	./gen_config.sh

.PHONY: install
install:
	./install.sh

.PHONY: login
login:
	./login.sh

.PHONY: purge
purge:
	./purge.sh

.PHONY: all
all: clean chart gen-config install

## one-offs:

.PHONY: scf-precheck
scf-precheck:
	./precheck.sh

.PHONY: scf-brats-setup
scf-brats-setup:
	./brats_setup.sh

.PHONY: upgrade
upgrade:
	./upgrade.sh

.PHONY: build-scf-from-source
build-scf-from-source:
	./build.sh

.PHONY: scf-klog
scf-klog:
	./klog.sh

.PHONY: stemcell_build
stemcell_build:
	./stemcell_build.sh
