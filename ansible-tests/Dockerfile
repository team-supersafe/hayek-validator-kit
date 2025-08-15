ARG SOLANA_RELEASE=2.2.20

# Base Ubuntu with common tooling
FROM ubuntu:24.04 AS ubuntu-base
ARG SOLANA_RELEASE
LABEL maintainer="hayek-validator-kit"

ENV DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
       apt-utils \
       locales \
       python3-dev \
       python3-setuptools \
       python3-pip \
       software-properties-common \
       rsyslog sudo iproute2 \
       openssh-client openssh-server git curl nano openssl tar jq less tree \
       at cron logrotate \
    && apt-get purge -y --auto-remove \
    && apt-get clean \
    && rm -Rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man

# Fix potential UTF-8 errors with ansible-test.
RUN locale-gen en_US.UTF-8

# Remove useless Python environment warning flag.
RUN rm -rf /usr/lib/python3.12/EXTERNALLY-MANAGED || true


# Download Solana/Agave binaries (used by ansible-control)
FROM alpine AS solana-binaries
ARG SOLANA_RELEASE

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


# Molecule runner image
FROM ubuntu-base AS molecule-runner
ARG SOLANA_RELEASE

# Install Docker CLI and Ansible/Molecule via Pip
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates gnupg lsb-release curl \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      docker-ce-cli docker-compose-plugin docker-buildx-plugin \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PIP_PACKAGES="ansible passlib molecule molecule-plugins[docker] ansible-lint yamllint"
RUN pip3 install $PIP_PACKAGES

RUN mkdir -p /opt/code/tools
WORKDIR /hayek-validator-kit/ansible-tests/rbac-tests

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

ENV SOLANA_INSTALL_DIR=/root/.local/share/solana/install

RUN --mount=type=cache,target=/root/.cache \
    mkdir -p ~/.ssh \
    && mkdir -p "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE"

COPY --from=solana-binaries --chown=root:root "/solana-release" "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release"

RUN --mount=type=cache,target=/root/.cache \
    ln -sf "$SOLANA_INSTALL_DIR/releases/$SOLANA_RELEASE/solana-release" "$SOLANA_INSTALL_DIR/active_release" \
    && export PATH=$SOLANA_INSTALL_DIR/active_release/bin:$PATH \
    && solana --version \
    && echo "export PATH=$SOLANA_INSTALL_DIR/active_release/bin:"'$PATH' >> ~/.profile \
    && echo 'if [ -f ~/.bashrc ]; then source ~/.bashrc; fi' >> ~/.profile \
    && echo 'export PS1="\[\e[0;32m\]test-runner\[\e[m\]:\w\$ "' >> ~/.bashrc


RUN echo '# Welcome message for test-runner' >> ~/.bashrc \
    && echo 'show_test_help() {' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;36m=========================================="' >> ~/.bashrc \
    && echo '    echo -e "🧪 HAYEK VALIDATOR KIT - TEST RUNNER"' >> ~/.bashrc \
    && echo '    echo -e "==========================================\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;32m📋 Available Test Commands:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;33m🔐 RBAC Tests (you are here):\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Full test suite with specific CSV file:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule test -s default -- -e csv_file=iam_setup.csv"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;90m  → Runs complete suite: converge + verify + destroy\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e ""' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Initial setup (configuration only):\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule converge -s default -- -e csv_file=iam_setup.csv"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;90m  → Creates container and applies RBAC configuration\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e ""' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Idempotency test:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule idempotence -s default -- -e csv_file=iam_setup.csv"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;90m  → Verifies that changes are idempotent\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e ""' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Verification on active container:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule verify                  # Run verification tests only"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;90m  → Runs RBAC tests without recreating container\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e ""' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Direct container access:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule login                   # SSH into testing container"' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;90m  → For manual debugging and exploration\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e ""' >> ~/.bashrc \
    && echo '    echo -e "  \\033[1;32m# Cleanup:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  molecule destroy                 # Remove testing containers"' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;33m📁 Important Paths:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  /hayek-validator-kit/            # Main project directory"' >> ~/.bashrc \
    && echo '    echo -e "  /root/new-metal-box/             # CSV configuration files"' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;32m💡 Quick Tip:\\033[0m"' >> ~/.bashrc \
    && echo '    echo -e "  • Use '\''help'\'' to show this message again"' >> ~/.bashrc \
    && echo '    echo -e "\\n\\033[1;36m==========================================\\033[0m\\n"' >> ~/.bashrc \
    && echo '}' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo '# Alias for easy access' >> ~/.bashrc \
    && echo 'alias help="show_test_help"' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo '# Show welcome message on login' >> ~/.bashrc \
    && echo 'show_test_help' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo '# Auto-navigate to RBAC tests directory' >> ~/.bashrc \
    && echo 'cd /hayek-validator-kit/ansible-tests/rbac-tests 2>/dev/null || echo "RBAC tests directory not found"' >> ~/.bashrc

CMD [ "bash" ]


# Pristine Ubuntu with systemd and ssh (host-charlie)
FROM ubuntu-base AS naked-builder

# Set workdir
RUN mkdir -p /opt/code/tools
WORKDIR /opt/code/tools

# Copy SSH setup script
RUN mkdir -p /opt/scripts
COPY scripts/setup-ssh-keys.sh /opt/scripts/setup-ssh-keys.sh
RUN chmod +x /opt/scripts/setup-ssh-keys.sh

# Give ubuntu passwordless sudo access for ansible playbooks testing
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

SHELL [ "/bin/bash", "-c" ]
ENV LANG=C.UTF-8

# Start ssh server on boot
RUN --mount=type=cache,target=/root/.cache \
    systemctl enable ssh

CMD [ "bash" ]

