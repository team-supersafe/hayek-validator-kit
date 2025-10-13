#!/bin/bash
# monitoring-entrypoint.sh - Install Solana CLI for monitoring container

echo "[monitoring-setup] Starting Solana CLI installation..."

# Detect architecture and set download URL
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)
    ARCH="x86_64-unknown-linux-gnu"
    DOWNLOAD_ROOT="https://github.com/anza-xyz/agave/releases/download"
    ;;
  aarch64)
    ARCH="aarch64-unknown-linux-gnu"
    DOWNLOAD_ROOT="https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download"
    ;;
  *)
    echo "[monitoring-setup] ERROR: Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

# Install Solana CLI if not present
if ! command -v solana &> /dev/null; then
  SOLANA_RELEASE="${SOLANA_RELEASE:-2.2.20}"
  INSTALL_DIR="/home/ubuntu/.local/share/solana/install"
  RELEASE_DIR="$INSTALL_DIR/releases/$SOLANA_RELEASE"
  ACTIVE_RELEASE="$INSTALL_DIR/active_release"
  DOWNLOAD_URL="$DOWNLOAD_ROOT/v${SOLANA_RELEASE}/solana-release-${ARCH}.tar.bz2"

  echo "[monitoring-setup] Downloading Solana CLI..."

  mkdir -p "$RELEASE_DIR"
  curl -sSfL "$DOWNLOAD_URL" -o "/tmp/solana-${ARCH}.tar.bz2" || {
    echo "[monitoring-setup] ERROR: Download failed" >&2
    exit 1
  }

  tar -xjf "/tmp/solana-${ARCH}.tar.bz2" -C "$RELEASE_DIR" || {
    echo "[monitoring-setup] ERROR: Extraction failed" >&2
    exit 1
  }

  rm -f "/tmp/solana-${ARCH}.tar.bz2"
  ln -sf "$RELEASE_DIR/solana-release" "$ACTIVE_RELEASE"
  export PATH="$ACTIVE_RELEASE/bin:$PATH"
  echo "export PATH=$ACTIVE_RELEASE/bin:"'$PATH' >> /home/ubuntu/.profile

  echo "[monitoring-setup] Solana CLI installed successfully: $(solana --version)"
else
  echo "[monitoring-setup] Solana CLI already installed: $(solana --version)"
fi

echo "[monitoring-setup] Monitoring container ready."
