#!/usr/bin/env bash

. scripts/include/common.sh
. .envrc

set -Eeuxo pipefail

minikube stop
