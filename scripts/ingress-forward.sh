#!/bin/bash

set -ex 

. scripts/include/common.sh
. .envrc

exec kubectl port-forward -n default pod/socksproxy 2224:8000