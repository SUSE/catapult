#!/bin/bash

. ./defaults.sh
. ../../include/common.sh
. .envrc

if [ -z "$SCF_LOCAL" ]; then
    [ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO" scf
    git reset --hard "$SCF_BRANCH"
    git submodule sync --recursive && \
    git submodule update --init --recursive && \
    git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
    pushd scf || exit
else
    pushd "$SCF_LOCAL" || exit
fi

sed -i 's|exit 1||' make/kube-dist || true
sed -i 's|exit 1||' make/bundle-dist || true
docker exec "$DOCKER_OPTS" \
-ti "$CLUSTER_NAME"-control-plane \
/bin/bash -exc ' apt-get update && apt-get install -y ruby git wget make; cd /code/scf && chmod -R 777 src && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep bundle-dist'
cp -rfv output/*.zip ../
unzip -o ./*.zip
popd || exit
