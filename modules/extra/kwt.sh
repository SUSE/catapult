#!/bin/bash

. ./defaults.sh
. ../../include/common.sh

wget https://github.com/k14s/kwt/releases/download/$KWT_VERSION/kwt-$KWT_OS_TYPE -O bin/kwt
chmod +x bin/kwt
