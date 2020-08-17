FROM registry.opensuse.org/opensuse/leap/15.2/images/totest/containers/opensuse/leap:15.2

ARG VERSION
ARG REPO_ENV
ARG REPO

ARG IBS="http://download.suse.de/ibs"
# ARG IBS="http://ibs-mirror.prv.suse.net/ibs"
RUN for repo in SLE-Product-SLES SLE-Module-Basesystem SLE-Module-Containers SLE-Module-Public-Cloud; do \
    zypper ar $IBS/SUSE/Products/$repo/15-SP2/x86_64/product ${repo}_pool; \
    zypper ar $IBS/SUSE/Updates/$repo/15-SP2/x86_64/update ${repo}_updates; \
done
RUN zypper ar $IBS/SUSE/Products/SUSE-CAASP/4.5/x86_64/product CAASP_pool
# RUN zypper ar $IBS/Updates/SUSE-CAASP/4.5/x86_64/update CAASP_updates
RUN zypper ar --no-gpgcheck $IBS"${REPO}" "skuba-${REPO_ENV}"

RUN zypper refresh; zypper -n dist-upgrade
RUN zypper --gpg-auto-import-keys ref -s


# RUN zypper ar --no-gpgcheck "http://download.suse.de/ibs/SUSE/Products/SUSE-CAASP/4.5/x86_64/product/" caasp-product
RUN zypper ar --no-gpgcheck "$IBS/SUSE:/CA/SLE_15_SP2/SUSE:CA.repo"
# RUN zypper ref
RUN zypper in --auto-agree-with-licenses --no-confirm -t product caasp
RUN zypper in --auto-agree-with-licenses --no-confirm ca-certificates-suse openssh

RUN zypper -n in -t pattern SUSE-CaaSP-Management
RUN zypper up
RUN zypper clean -a

VOLUME ["/app"]

WORKDIR /app
