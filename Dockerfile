FROM mcr.microsoft.com/cbl-mariner/base/core:2.0

ARG PKL_VERSION="0.25.3"
ARG PKL_ARCH="amd64"
ARG KUBECTL_VERSION="1.28.10"
ARG KUBECTL_ARCH="amd64"

RUN tdnf install -y ca-certificates \
  && tdnf clean all \
  && rm -rf /var/cache/tdnf

RUN curl -L https://github.com/apple/pkl/releases/download/${PKL_VERSION}/pkl-linux-${PKL_ARCH} -o /bin/pkl && \
  chmod +x /bin/pkl && \
  /bin/pkl --version

RUN curl -L https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl -o /bin/kubectl && \
  chmod +x /bin/kubectl && \
  /bin/kubectl version --client

COPY ./pkl /opt/bagapi/
