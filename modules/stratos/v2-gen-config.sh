#!/bin/bash

. ../../include/common.sh
. .envrc

info "Generating stratos config values from scf values"

cp kubecf-config-values.yaml stratos-config-values.yaml
for patch in "$ROOT_DIR"/modules/stratos/patches/*.yaml; do
    echo "Applying patch $patch"
    trunion -d kubecf=kubecf-config-values.yaml \
                    -d stratos=stratos-config-values.yaml \
                    -p "$patch" \
                    > stratos-config-values_temp.yaml
    mv stratos-config-values_temp.yaml stratos-config-values.yaml
done

ok "Stratos config values generated"
