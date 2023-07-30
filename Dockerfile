FROM debian:buster-slim as base

RUN apt-get update && \
  apt-get install -y --no-install-recommends \
  ca-certificates \
  openssh-client sshpass \
  zip unzip \
  curl \
  wget \
  host \
  jq \
  make \
  sudo \
  moreutils \
  python3 \
  python3-pip \
  git && \
  rm -rf /var/lib/apt/lists/* && \
  update-ca-certificates
RUN pip3 install pyyaml

# Docker
FROM base as docker
ENV DOCKER_VERSION=24.0.5
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
  && mv docker-${DOCKER_VERSION}.tgz docker.tgz \
  && tar xzvf docker.tgz \
  && mv docker/docker /usr/local/bin \
  && rm -r docker docker.tgz

# Docker Compose
FROM base as docker_compose
ENV DOCKER_COMPOSE_VERSION=2.20.2
RUN curl -L https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose

# kubectl
FROM base as kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x kubectl && mv kubectl /usr/local/bin

# helm
FROM base as helm
ENV HELM_VERSION=v3.6.2
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm.tar.gz \
  && tar xzvf helm.tar.gz \
  && mv linux-amd64/helm /usr/local/bin \
  && rm -r linux-amd64 helm.tar.gz

# terraform
FROM base as terraform
ENV TERRAFORM_VERSION=1.5.4
RUN curl -fsSL https://releases.hashicorp.com/terraform/$TERRAFORM_VERSION/terraform_${TERRAFORM_VERSION}_linux_amd64.zip -o terraform.zip \
  && unzip terraform.zip \
  && mv terraform /usr/local/bin \
  && rm -r terraform.zip

# skaffold
FROM base as skaffold
RUN curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/v2.6.2/skaffold-linux-amd64 && \
  sudo install skaffold /usr/local/bin/

# yq
FROM base as yq
ENV YQ_VERSION=4.34.2
RUN curl -L https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 -o yq && \
  sudo install yq /usr/local/bin

# Final Image
FROM base
COPY --from=docker /usr/local/bin/docker /usr/local/bin
COPY --from=docker_compose /usr/local/bin/docker-compose /usr/local/bin
COPY --from=kubectl /usr/local/bin/kubectl /usr/local/bin
COPY --from=helm /usr/local/bin/helm /usr/local/bin
COPY --from=terraform /usr/local/bin/terraform /usr/local/bin
COPY --from=skaffold /usr/local/bin/skaffold /usr/local/bin
COPY --from=yq /usr/local/bin/yq /usr/local/bin
