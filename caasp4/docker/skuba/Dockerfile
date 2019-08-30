FROM registry.opensuse.org/opensuse/leap/15.1/images/totest/containers/opensuse/leap:15.1

ARG VERSION
ARG REPO_ENV
ARG REPO

RUN zypper ar --no-gpgcheck "${REPO}" "skuba-${REPO_ENV}" && \
    zypper ar --no-gpgcheck "http://download.suse.de/ibs/SUSE:/CA/SLE_15_SP1/SUSE:CA.repo" && \
    zypper ref && \
    zypper in --auto-agree-with-licenses --no-confirm "skuba-${VERSION}" terraform ca-certificates-suse openssh && \
    zypper clean -a

VOLUME ["/app"]

WORKDIR /app
