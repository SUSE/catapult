#!/usr/bin/env bash

. ../include/common.sh

# use extended regexp patterns for matching:
shopt -s extglob
# remove empty matches when search-on-depth, instead of failing:
shopt -s nullglob
# match **/ as all dirs and subdirs:
shopt -s globstar

info "Linting shell scripts" && debug_mode
SH_FILES=$(ls "$ROOT_DIR"/**/*.{sh,ksh,bash} | grep -v "shunit2" | grep -v "build*")
shellcheck --severity=error $SH_FILES || retcode=1

info "Linting yamls" && debug_mode
YML_FILES=$(ls "$ROOT_DIR"/**/*.{yaml,yml} | grep -v "shunit2" | grep -v "build*")
yamllint -d relaxed --strict $YML_FILES || retcode=1

if [[ $retcode == 1 ]] ; then
    err "Linting failed" && exit 1
else
    ok "Linting passed"
fi
