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

RUN zypper in -y python-xml
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
RUN unzip awscli-bundle.zip
RUN ./awscli-bundle/install
RUN rm -rf awscli-bundle*
RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator
RUN chmod +x aws-iam-authenticator && mv aws-iam-authenticator bin/

ADD . /catapult
WORKDIR /catapult
ENTRYPOINT [ "/usr/bin/make" ]
