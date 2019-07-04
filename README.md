# Deploy SCF with Eirini on kind

Turn on a SCF+Kind cluster with:

    CHART_URL="https://s3.amazonaws.com/xxx.zip" \
    DOCKER_REGISTRY="my.private.registry" \
    DOCKER_ORG="my-org" \
    DOCKER_USERNAME="" \
    DOCKER_PASSWORD="" \
    make all

## Requirements:

* Helm
* Kubectl
* Docker running on the host
