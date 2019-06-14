#!/bin/bash
set -x

mkdir build
pushd build

wget https://github.com/kubernetes-sigs/kind/releases/download/0.2.1/kind-linux-amd64
mv kind-linux-amd64 kind
chmod +x kind

popd