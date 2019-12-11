#!/usr/bin/env bash

. ../../include/common.sh
. .envrc

# Purging it's a best-effort action
set +e

info "Purging all apps, buildpacks and services from the CF instance"

# Delete leftover apps
for app in $(cf apps | gawk '{print $1}'); do cf delete -f $app; done

# Delete all buildpacks (in case there are leftovers)
for buildpack in $(cf buildpacks | tail -n +4 | gawk '{print $1}'); do cf delete-buildpack -f $buildpack; done

if [ -n "$CF_STACK" ]; then
    for buildpack in $(cf buildpacks | tail -n +4 | gawk '{print $1}'); do cf delete-buildpack -f $buildpack -s "$CF_STACK"; done
fi

# Delete all services
for service in $(cf services | tail -n +4 | gawk '{print $1}'); do cf delete-service -f $service; done

ok "Purge completed"
