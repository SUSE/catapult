#!/bin/bash

. ../../include/common.sh
. .envrc


MINIKUBE_VERSION=latest
if [[ "$OSTYPE" == "darwin"* ]]; then
    MINIKUBE_BIN=minikube-darwin-amd64
else
    MINIKUBE_BIN=minikube-linux-amd64
fi

minikubepath=bin/minikube
if [ ! -e "$minikubepath" ]; then
    curl -Lo minikube https://storage.googleapis.com/minikube/releases/"$MINIKUBE_VERSION"/"$MINIKUBE_BIN"
    chmod +x minikube && mv minikube bin/
fi

dockermachinedriverkvm2path=bin/docker-machine-driver-kvm2
if [ ! -e "$dockermachinedriverkvm2path" ]; then
    curl -Lo docker-machine-driver-kvm2 https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
    chmod +x docker-machine-driver-kvm2 && mv docker-machine-driver-kvm2 bin/
fi

popd || exit
