.DEFAULT_GOAL := all

.PHONY: clean
clean:
	./clean.sh

.PHONY: chart
chart:
	./chart.sh

.PHONY: gen-config
gen-config:
	./gen-config.sh

.PHONY: install
install:
	./install.sh

.PHONY: upgrade
upgrade: chart gen-config
	./upgrade.sh

.PHONY: all
all: clean chart gen-config install
