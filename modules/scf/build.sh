#!/bin/bash

. ../../include/common.sh
. .envrc


[ ! -d "scf" ] && git clone --recurse-submodules "$SCF_REPO" scf

pushd scf
    git reset --hard "$SCF_BRANCH"
    git submodule sync --recursive && \
    git submodule update --init --recursive && \
    git submodule foreach --recursive "git checkout . && git reset --hard && git clean -dffx"
    if [ "$SCF_OPERATOR" == "true" ]; then
        if [ ! -e "../bin/bazel" ]; then
            wget "https://github.com/bazelbuild/bazel/releases/download/1.1.0/bazel-1.1.0-linux-x86_64" -O ../bin/bazel
            chmod +x ../bin/bazel
        fi
        bazel build //deploy/helm/kubecf:chart
        tar -xvf bazel-bin/deploy/helm/kubecf/kubecf-*.tgz -C ../
    else
        sed -i 's|exit 1||' make/kube-dist || true
        sed -i 's|exit 1||' make/bundle-dist || true
        docker exec "$DOCKER_OPTS" \
        -ti "$CLUSTER_NAME"-control-plane \
        /bin/bash -exc ' apt-get update && apt-get install -y ruby git wget make; cd /code/scf && chmod -R 777 src && source .envrc && ./bin/dev/install_tools.sh && make vagrant-prep bundle-dist'
        cp -rfv output/*.zip ../
        unzip -o ./*.zip
    fi
popd

