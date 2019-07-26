FROM opensuse/tumbleweed:latest
RUN zypper ref && zypper in -y git zip wget docker ruby gzip make jq curl which unzip go
RUN curl -L https://git.io/get_helm.sh | bash
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl
RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
RUN mv cf /usr/local/bin && chmod +x /usr/local/bin/cf
ADD . /bkindwscf
WORKDIR /bkindwscf
ENTRYPOINT [ "/usr/bin/make" ]
