FROM ubuntu:20.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# todo must check base img compatibility of some of these indexed libs (e.g. apt search libicu ). Automate this process
RUN apt-get update && apt-get install -y  \
    ca-certificates \
    curl \
    jq \
    git \
    iputils-ping \
    libcurl4 \
    libicu66 \
    libunwind8 \
    netcat \
    libssl1.1 \
    maven \
    unzip \
    docker.io \
    && rm -rf /var/lib/apt/lists/*

#--no-install-recommends

# installl helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && chmod 700 get_helm.sh \
    &&./get_helm.sh

RUN curl -LsS https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH=amd64
ARG AGENT_VERSION=2.185.1

WORKDIR /azp
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz; \
    else \
      AZP_AGENTPACKAGE_URL=https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-${TARGETARCH}-${AGENT_VERSION}.tar.gz; \
    fi; \
    curl -LsS "$AZP_AGENTPACKAGE_URL" | tar -xz

COPY start.sh .
RUN chmod +x start.sh

#install jdk
RUN apt-get update && apt-get install -y \
    openjdk-8-jdk \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/* 

ENV JAVA_HOME_11_X64=/usr/lib/jvm/java-11-openjdk-amd64
ENV JAVA_HOME_8_X64=/usr/lib/jvm/java-1.8.0-openjdk-amd64

# install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# install azure devops cli
RUN az config set extension.use_dynamic_install=yes_without_prompt \
    && az extension add --name azure-devops \
    && az devops -h

#/bin/java
ENTRYPOINT [ "./start.sh" ]