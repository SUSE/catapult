#!/bin/bash

function red()   { printf '\e[31m%b\e[0m' "$1" ; }
function green() { printf '\e[32m%b\e[0m' "$1" ; }
function blue()  { printf '\e[34m%b\e[0m' "$1" ; }
function cyan()  { printf '\e[36m%b\e[0m' "$1" ; }
