FROM opensuse/tumbleweed:latest
# Catapult dependencies:
RUN zypper ref && zypper in -y git zip wget docker ruby gzip make jq python-yq curl which unzip bazel1.2 direnv
RUN echo 'eval $(direnv hook bash)' >> ~/.bashrc

RUN wget "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_linux" -O yaml-patch
RUN mv yaml-patch /usr/local/bin && chmod +x /usr/local/bin/yaml-patch

# Extras, mostly for the terminal image (that could be split in another image)
RUN zypper in -y vim zsh tmux glibc-locale glibc-i18ndata python ruby python3 python3-pip cf-cli

RUN zypper ar --priority 100 https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Factory/devel:languages:go.repo && \
zypper --gpg-auto-import-keys -n in -y --from=devel_languages_go go1.13

RUN zypper ar --priority 100 https://download.opensuse.org/repositories/Cloud:Tools/openSUSE_Tumbleweed/Cloud:Tools.repo && \
zypper --gpg-auto-import-keys -n in --no-recommends -y kubernetes-client

# k8s backends dependencies:
RUN zypper in -y terraform aws-cli aws-iam-authenticator

RUN curl -o google-cloud-sdk.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-264.0.0-linux-x86_64.tar.gz && \
  tar -xvf google-cloud-sdk.tar.gz && \
  rm google-cloud-sdk.tar.gz && \
  pushd google-cloud-sdk || exit && \
  bash ./install.sh -q && \
  popd || exit && \
  echo "source /google-cloud-sdk/path.bash.inc" >> ~/.bashrc

RUN curl -o kubectl-aws https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl
RUN mv kubectl-aws /usr/local/bin/ && chmod +x /usr/local/bin/kubectl-aws

ADD . /catapult
WORKDIR /catapult
ENTRYPOINT [ "/usr/bin/make" ]
