#!/bin/bash
set -ex 

. scripts/include/common.sh

wget "$CHART_URL" -O chart.zip

unzip chart.zip