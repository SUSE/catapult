.DEFAULT_GOAL := all

.PHONY: smoke
smoke:
	./tests_smoke.sh

.PHONY: smoke-kube
smoke-kube:
	./tests_kubesmokes.sh

.PHONY: kubecats
kubecats:
	./tests_kubecats.sh

.PHONY: brats
brats:
	./tests_brats.sh

.PHONY: test-eirini-persi
test-eirini-persi:
	./tests_eirini_persi.sh

.PHONY: smoke-scf
smoke-scf:
	./tests_smoke_scf.sh

.PHONY: cats
cats:
	./tests_cats.sh

.PHONY: sample
smoke:
	./sample.sh

# test all the things!
.PHONY: all
# Enable only reliable ones:
all: smoke
