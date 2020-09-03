#!/usr/bin/env bash

# Global private defaults (not shown on output)
###############################################

export DOCKER_USERNAME="${DOCKER_USERNAME:-}"
export DOCKER_PASSWORD="${DOCKER_PASSWORD:-}"

# Only for scf, for kubecf we let it be generated, and read it
export CLUSTER_PASSWORD="${CLUSTER_PASSWORD:-password}"
