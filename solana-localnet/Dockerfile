FROM ubuntu:24.04 AS ubuntu-base
LABEL maintainer="eydel.rivero@gmail.com"

ARG SOLANA_RELEASE=2.2.14

ENV DEBIAN_FRONTEND=noninteractive

# Clean up docker and handle apt locks properly
RUN rm -rf /var/lib/apt/lists/* && \
    rm -f /var/cache/apt/archives/lock && \
    rm -f /var/lib/dpkg/lock* && \
    dpkg --configure -a && \
    apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server nano curl git openssl tar jq less tree \
        bzip2 zstd xz-utils lbzip2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install dependencies with proper lock handling
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
       apt-utils \
       at \
       cron \
       clang \
       libclang-dev \
       locales \
       logrotate \
       python3-dev \
       python3-setuptools \
       python3-pip \
       python3-yaml \
       software-properties-common \
       rsyslog sudo iproute2 \
       openssh-client git curl nano openssl tar jq less tree \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/share/doc \
    && rm -rf /usr/share/man

# Remove useless Python environment warning flag.
RUN sudo rm -rf /usr/lib/python3.12/EXTERNALLY-MANAGED

# End of ubuntu-base


FROM alpine AS solana-binaries
ARG SOLANA_RELEASE=2.2.14

# ADD "https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download/$SOLANA_RELEASE/solana-release-aarch64-unknown-linux-gnu.tar.bz2" "/$SOLANA_RELEASE.tar.bz2"

RUN CPU_TYPE="$(uname -m)" \
  && SOLANA_DOWNLOAD_ROOT= \
  && case "$CPU_TYPE" in \
    x86_64) ;; \
    aarch64) ;; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && if [ "$CPU_TYPE" = "aarch64" ]; then \
    SOLANA_DOWNLOAD_ROOT="https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download"; \
  else \
    SOLANA_DOWNLOAD_ROOT="https://github.com/anza-xyz/agave/releases/download"; \
  fi \
  && SOLANA_DOWNLOAD_URL="$SOLANA_DOWNLOAD_ROOT/v${SOLANA_RELEASE}/solana-release-${CPU_TYPE}-unknown-linux-gnu.tar.bz2" \
  && apk add --no-cache curl tar \
  && mkdir -p "/downloads" \
  && echo "Downloading ${SOLANA_DOWNLOAD_URL}..." \
  && curl -sSfL "$SOLANA_DOWNLOAD_URL" -o "/downloads/${SOLANA_RELEASE}.tar.bz2"

RUN --mount=type=cache,target=/root/.cache \
    tar -xvjf "/downloads/${SOLANA_RELEASE}.tar.bz2" --directory "/"

# End of solana-binaries


# Dockerfile
FROM ubuntu-base AS ansible-control-builder
LABEL maintainer="eydel.rivero@gmail.com"

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8

# Install Ansible via Pip.
ENV PIP_PACKAGES="ansible passlib"
RUN pip3 install $PIP_PACKAGES

# Set workdir
RUN mkdir -p /opt/code/tools
WORKDIR /opt/code/tools

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

ENV SOLANA_INSTALL_DIR=/root/.local/share/solana/install

RUN --mount=type=cache,target=/root/.cache \
    mkdir -p ~/.ssh \
    && mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE"

# # COPY "./v$SOLANA_RELEASE_aarch64-unknown-linux-gnu.tar.bz2" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2"
# RUN curl -sSfL "https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download/$SOLANA_RELEASE/aarch64-unknown-linux-gnu.tar.bz2" -o "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2"

# RUN --mount=type=cache,target=/root/.cache \
#     mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE" \
#     && tar -xvjf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2" --directory "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE" \
#     && rm -f "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2"

COPY --from=solana-binaries --chown=sol:sol "/solana-release" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release"

RUN --mount=type=cache,target=/root/.cache \
    ln -sf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release" "$SOLANA_INSTALL_DIR/active_release" \
    && export PATH=$SOLANA_INSTALL_DIR/active_release/bin:$PATH \
    && solana --version \
    && echo "export PATH=$SOLANA_INSTALL_DIR/active_release/bin:"'$PATH' >> ~/.bashrc \
    && echo 'export PS1="\[\e[0;32m\]ansible-control\[\e[m\]:\w\$ "' >> ~/.bashrc

# Default command
CMD [ "bash" ]

# End of ansible-control


# Dockerfile
FROM ubuntu-base AS gossip-entrypoint-builder
LABEL maintainer="eydel.rivero@gmail.com"

ARG SOLANA_RELEASE=2.2.14

# set workdir
RUN mkdir -p /opt/code/tools
WORKDIR /opt/code/tools

# Install runtime OS package dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
        apt-get install -y --no-install-recommends \
        openssh-server nano curl git openssl tar jq less tree && \
        apt-get purge -y --auto-remove

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

# Start ssh server
RUN --mount=type=cache,target=/root/.cache \
    sudo systemctl enable ssh

ENV SOLANA_INSTALL_DIR=/root/.local/share/solana/install

RUN --mount=type=cache,target=/root/.cache \
    mkdir -p ~/.ssh \
    && mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE"

# COPY "./v$SOLANA_RELEASE_aarch64-unknown-linux-gnu.tar.bz2" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2"
# RUN curl -sSfL "https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download/$SOLANA_RELEASE/aarch64-unknown-linux-gnu.tar.bz2" -o "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2"

# RUN --mount=type=cache,target=/root/.cache \
#     mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE" \
#     && tar -xvjf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE.tar.bz2" --directory "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE"

COPY --from=solana-binaries --chown=sol:sol "/solana-release" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release"

RUN --mount=type=cache,target=/root/.cache \
    ln -sf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release" "$SOLANA_INSTALL_DIR/active_release" \
    && export PATH=$SOLANA_INSTALL_DIR/active_release/bin:$PATH \
    && solana --version \
    && echo "export PATH=$SOLANA_INSTALL_DIR/active_release/bin:"'$PATH' >> ~/.bashrc

# RPC JSON
EXPOSE 8899/tcp
# RPC pubsub
EXPOSE 8900/tcp
# gossip entrypoint
EXPOSE 8001/tcp
# (future) bank service
EXPOSE 8901/tcp
# bank service
EXPOSE 8902/tcp
# faucet
EXPOSE 9900/tcp
# tvu
EXPOSE 8000/udp
# gossip
EXPOSE 8001/udp
# tvu_quic
EXPOSE 8002/udp
# tpu
EXPOSE 8003/udp
# tpu_forwards
EXPOSE 8004/udp
# retransmit
EXPOSE 8005/udp
# repair
EXPOSE 8006/udp
# serve_repair
EXPOSE 8007/udp
# broadcast
EXPOSE 8008/udp
# tpu_vote
EXPOSE 8009/udp

COPY "./localnet-gossip-entrypoint-setup.sh" "/usr/bin"
ENV PATH=$SOLANA_INSTALL_DIR/active_release/bin:$PATH
ENTRYPOINT /usr/bin/localnet-gossip-entrypoint-setup.sh
CMD [""]

# End of gossip-entrypoint-builder


# Dockerfile
FROM ubuntu-base AS validator-builder
LABEL maintainer="eydel.rivero@gmail.com"

ARG SOLANA_RELEASE=2.2.14

# set workdir
RUN mkdir -p /opt/code/tools
WORKDIR /opt/code/tools

# Install runtime OS package dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
        apt-get install -y --no-install-recommends \
        openssh-server nano curl git openssl tar jq less tree && \
        apt-get purge -y --auto-remove

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

# Start ssh server
RUN --mount=type=cache,target=/root/.cache \
    sudo systemctl enable ssh

ENV SOLANA_INSTALL_DIR=/home/sol/.local/share/solana/install

# Configure sol user
RUN --mount=type=cache,target=/root/.cache \
    adduser --disabled-password --gecos "" sol \
    && echo "sol:solpw" | chpasswd \
    && usermod -aG sudo sol \
    && echo "sol ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER sol

RUN --mount=type=cache,target=/root/.cache \
    mkdir -p ~/.ssh \
    && mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE"

COPY --from=solana-binaries --chown=sol:sol "/solana-release" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release"

RUN --mount=type=cache,target=/root/.cache \
    ln -sf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release" "$SOLANA_INSTALL_DIR/active_release" \
    && export PATH=$SOLANA_INSTALL_DIR/active_release/bin:$PATH \
    && solana --version \
    && echo "export PATH=$SOLANA_INSTALL_DIR/active_release/bin:"'$PATH' >> ~/.bashrc

# switch back to root user so the base container CMD ["/lib/systemd/systemd"] can run
# otherwise the container will exit with unknown error 255
USER root

# End of validator


# Dockerfile - This target is used to create a pristine image with basic tooling, users and ssh server
# The purpose of this image is to test rust and solana cli install from scratch
FROM ubuntu-base AS naked-builder
LABEL maintainer="eydel.rivero@gmail.com"

# Set workdir
RUN mkdir -p /opt/code/tools
WORKDIR /opt/code/tools

# Install runtime OS package dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
        apt-get install -y --no-install-recommends \
        openssh-server nano curl git openssl tar jq less tree && \
        apt-get purge -y --auto-remove

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

# Start ssh server
RUN --mount=type=cache,target=/root/.cache \
    sudo systemctl enable ssh

# Configure sol user
RUN --mount=type=cache,target=/root/.cache \
    adduser --disabled-password --gecos "" sol \
    && echo "sol:solpw" | chpasswd \
    && usermod -aG sudo sol \
    && echo "sol ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

USER sol

USER root

# Default command
CMD [ "bash" ]

# End of pristine
