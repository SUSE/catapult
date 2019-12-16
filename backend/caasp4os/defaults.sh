#!/bin/bash

# Caasp4os options
##################

CAASP_VER=${CAASP_VER:-"update"} # devel, staging, update, product
STACK=${STACK:-"$(whoami)-caasp4-${CAASP_VER::3}-$CLUSTER_NAME"}
