#!/bin/bash
set -ex 
pushd build

CHART_URL="${CHART_URL:-}"

wget "$CHART_URL" -O chart.zip

unzip chart.zip