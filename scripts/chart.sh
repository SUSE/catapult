#!/bin/bash
set -ex 

. scripts/include/common.sh

if [ -z "$CHART_URL" ]; then
    echo "No chart url given - using latest public release from GH" 
    CHART_URL=$(curl -s https://api.github.com/repos/SUSE/scf/releases/latest | grep "browser_download_url.*zip" | cut -d : -f 2,3 | tr -d \" | tr -d " ")
fi

wget "$CHART_URL" -O chart.zip

unzip -o chart.zip