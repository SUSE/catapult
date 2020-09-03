# no default goal
# .DEFAULT_GOAL :=

.PHONY: eirini_release
eirini_release:
	./eirini_release.sh

.PHONY: eirinifs
eirinifs:
	./eirinifs.sh

.PHONY: airgap-up
airgap-up: airgap-down
	./airgap_up.sh

PHONY: airgap-down
airgap-down:
	./airgap_down.sh

.PHONY: tf_force_clean
tf_force_clean:
	./tf_force_clean.sh

.PHONY: tf_auto_deploy
tf_auto_deploy:
	./tf_auto_deploy.sh
