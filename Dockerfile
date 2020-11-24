FROM registry.opensuse.org/opensuse/tumbleweed:latest
# Catapult dependencies:
RUN zypper ref && zypper in --no-recommends -y git zip wget docker ruby gzip make jq curl which unzip bazel1.2 direnv
RUN echo 'eval $(direnv hook bash)' >> ~/.bashrc

RUN wget "https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64" -O /usr/local/bin/yq && \
  chmod +x /usr/local/bin/yq

RUN wget "https://github.com/krishicks/yaml-patch/releases/download/v0.0.10/yaml_patch_linux" -O /usr/local/bin/yaml-patch && \
  chmod +x /usr/local/bin/yaml-patch

# Extras, mostly for the terminal image (that could be split in another image)
RUN zypper in --no-recommends -y vim zsh tmux glibc-locale glibc-i18ndata python ruby python3 python3-pip cf-cli gnuplot

RUN zypper ar --priority 100 https://download.opensuse.org/repositories/devel:/languages:/go/openSUSE_Factory/devel:languages:go.repo && \
  zypper --gpg-auto-import-keys -n in --no-recommends -y --from=devel_languages_go go1.13

RUN zypper ar --priority 100 https://download.opensuse.org/repositories/Cloud:Tools/openSUSE_Tumbleweed/Cloud:Tools.repo && \
  zypper --gpg-auto-import-keys -n in --no-recommends -y Cloud_Tools:kubernetes-client

RUN helm_version=v3.1.1 \
  && wget https://get.helm.sh/helm-${helm_version}-linux-amd64.tar.gz -O - | tar xz -C /usr/bin --strip-components=1 linux-amd64/helm

# k8s backends dependencies:
RUN zypper in --no-recommends -y terraform

RUN zypper in --no-recommends -y python-xml
RUN curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" && \
  unzip awscli-bundle.zip && rm awscli-bundle.zip && \
  ./awscli-bundle/install --install-dir=/usr/lib/ --bin-location=/usr/local/bin/aws && \
  rm -rf awscli-bundle*

RUN curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator && \
  chmod +x aws-iam-authenticator && mv aws-iam-authenticator /usr/local/bin/

RUN curl https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-292.0.0-linux-x86_64.tar.gz \
         > /tmp/google-cloud-sdk.tar.gz \
  && mkdir -p /usr/local/gcloud \
  && tar -C /usr/local/gcloud -xvf /tmp/google-cloud-sdk.tar.gz && rm -rf /tmp/google-cloud-sdk.tar.gz \
  && /usr/local/gcloud/google-cloud-sdk/install.sh --override-components gcloud --quiet
ENV PATH $PATH:/usr/local/gcloud/google-cloud-sdk/bin

RUN curl -o kubectl-aws https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/kubectl && \
  mv kubectl-aws /usr/local/bin/ && chmod +x /usr/local/bin/kubectl-aws

RUN zypper in --no-recommends -y gcc libffi-devel python3-devel libopenssl-devel
RUN curl -o install.py https://azurecliprod.blob.core.windows.net/install.py && \
  sed -i 's/python3-devel/python38-devel/g' install.py && \
  printf "/usr/local/lib/azure-cli\n/usr/local/bin\n\n\n" | python3 ./install.py && \
  rm ./install.py

# KubeCF dependencies:
RUN zypper in --no-recommends -y python3-yamllint ShellCheck

RUN zypper rm -y glibc-locale && zypper clean --all

ADD . /catapult
WORKDIR /catapult
ENTRYPOINT [ "/usr/bin/make" ]
