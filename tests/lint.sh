#!/usr/bin/env bash

. ../include/common.sh

retcode=0
BUILDDIR_REGEXP="^$ROOT_DIR/build"

info "Linting shell scripts" && debug_mode
SH_FILES=$(find "$ROOT_DIR" -type f -name '*.sh' -o -name '*.ksh' -o -name '*.bash' | grep -v "shunit2" | grep -v "$BUILDDIR_REGEXP" )
shellcheck --severity=warning $SH_FILES || retcode=1

info "Linting yamls" && debug_mode
YML_FILES=$(find "$ROOT_DIR" -type f -name '*.yaml' -o -name '*.yml' | grep -v "shunit2" | grep -v "$BUILDDIR_REGEXP")
yamllint -d "{extends: relaxed, rules: {line-length: {max: 120}}}" --strict $YML_FILES || retcode=1

if [[ $retcode == 1 ]] ; then
    err "Linting failed" && exit 1
else
    ok "Linting passed"
fi
