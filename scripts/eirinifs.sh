#!/bin/bash
set -ex 

# Builds and patch eirinifs in a live cluster
. scripts/include/common.sh

EIRINIFS=${EIRINIFS:-https://github.com/os-fun/eirinifs.git}
EIRINISSH=${EIRINISSH:-https://github.com/SUSE/eirini-ssh}

[ ! -d "eirinifs" ] && git clone --recurse-submodules "${EIRINIFS}"
pushd eirinifs
git pull
popd
[ ! -d "diego-ssh" ] && git clone --recurse-submodules "${EIRINISSH}"
pushd diego-ssh
git pull
popd

pushd diego-ssh/cmd/sshd
go build
popd

cp -rfv diego-ssh/cmd/sshd/sshd eirinifs/image
pushd eirinifs

docker run --rm --privileged -it --workdir / -v $PWD:/eirinifs eirini/ci /bin/bash -c "/eirinifs/ci/build-eirinifs/task.sh && mv /go/src/github.com/cloudfoundry-incubator/eirinifs/image/eirinifs.tar /eirinifs/image"

popd
sudo chmod 777 image/eirinifs.tar &&  kubectl cp image/eirinifs.tar scf/bits-0:/var/vcap/store/bits-service/assets/eirinifs.tar 

kubectl exec -it -n scf bits-0 -- bash -c -l "monit restart bits-service"
