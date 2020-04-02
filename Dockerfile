FROM opensuse/tumbleweed:latest
RUN zypper ref && zypper in -y git zip wget docker ruby gzip make jq curl which unzip direnv
RUN echo 'eval $(direnv hook bash)' >> ~/.bashrc
# Extras, mostly for the terminal image (that could be split in another image)
RUN zypper in -y vim zsh tmux glibc-locale glibc-i18ndata python ruby python3 python3-pip


RUN zypper ar https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Factory/devel:languages:go.repo
RUN zypper --gpg-auto-import-keys -n in --from=devel_languages_go go1.13

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

RUN curl -L "https://packages.cloudfoundry.org/stable?release=linux64-binary&source=github" | tar -zx
RUN mv cf /usr/local/bin && chmod +x /usr/local/bin/cf

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
