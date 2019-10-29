#!/usr/bin/env bash

. ../include/common.sh

info "Linting shell scripts" && debug_mode
SH_FILES=$(find "$ROOT_DIR" -type f -name '*.sh' -o -name '*.ksh' -o -name '*.bash' | grep -v "shunit2" | grep -v '^build')

shellcheck --severity=error $SH_FILES || retcode=1

info "Linting yamls" && debug_mode
YML_FILES=$(find "$ROOT_DIR" -type f -name '*.yaml' -o -name '*.yml' | grep -v "shunit2" | grep -v '^build')
yamllint -d relaxed --strict $YML_FILES || retcode=1

if [[ $retcode == 1 ]] ; then
    err "Linting failed" && exit 1
else
    ok "Linting passed"
fi
