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
    pushd scf
else
    pushd "$SCF_LOCAL"
fi

GIT_HEAD=$(git log --pretty=format:'%h' -n 1)
if [ "$SCF_OPERATOR" == "true" ]; then
    rm -rfv bazel-bin/deploy/helm/kubecf/* || true
    bazel build //deploy/helm/kubecf
    tar -xvf bazel-bin/deploy/helm/kubecf/kubecf.tgz -C "$BUILD_DIR"
    SCF_CHART=kubecf-"$GIT_HEAD"
else
    sed -i 's|exit 1||' make/kube-dist || true
    sed -i 's|exit 1||' make/bundle-dist || true
    docker exec "$DOCKER_OPTS" \
    -ti "$CLUSTER_NAME"-control-plane \
    /bin/bash -exc ' apt-get update && apt-get install -y ruby git wget make; cd /code/scf && chmod -R 777 src && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep bundle-dist'
    cp -rfv output/*.zip ../
    unzip -o ./*.zip
    SCF_CHART=scf-"$GIT_HEAD"
fi
popd

# save SCF_CHART on cap-values configmap
kubectl patch -n kube-system configmap cap-values -p $'data:\n chart: "'$SCF_CHART'"'
