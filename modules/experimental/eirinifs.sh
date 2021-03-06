#!/bin/bash

# Builds and patch eirinifs in a live cluster

. ./defaults.sh
. ../../include/common.sh
. .envrc

[ ! -d "eirinifs" ] && git clone --recurse-submodules "${EIRINIFS}"
pushd eirinifs || exit
git pull
popd || exit
[ ! -d "diego-ssh" ] && git clone --recurse-submodules "${EIRINISSH}"
pushd diego-ssh || exit
git pull
popd || exit

pushd diego-ssh/cmd/sshd || exit
go build
popd || exit

cp -rfv diego-ssh/cmd/sshd/sshd eirinifs/image
pushd eirinifs || exit

docker run --rm --privileged -it --workdir / -v $PWD:/eirinifs eirini/ci /bin/bash -c "/eirinifs/ci/build-eirinifs/task.sh && mv /go/src/github.com/cloudfoundry-incubator/eirinifs/image/eirinifs.tar /eirinifs/image"

sudo chmod 777 image/eirinifs.tar &&  kubectl cp image/eirinifs.tar scf/bits-0:/var/vcap/store/bits-service/assets/eirinifs.tar

popd || exit
kubectl exec -it -n scf bits-0 -- bash -c -l "monit restart bits-service"
