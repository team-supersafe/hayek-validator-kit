#!/bin/bash

# Progress: container startup
echo "[monitoring-entrypoint] Step 1/5: Monitoring container started."
# Install Solana CLI from S3 if not present already

# Progress: detect architecture
echo "[monitoring-entrypoint] Step 2/5: Detecting architecture..."
SOLANA_RELEASE="${SOLANA_RELEASE:-2.2.20}"
ARCH="$(uname -m)"
if [ "$ARCH" = "x86_64" ]; then
  ARCH="x86_64-unknown-linux-gnu"
  SOLANA_DOWNLOAD_ROOT="https://github.com/anza-xyz/agave/releases/download"
elif [ "$ARCH" = "aarch64" ]; then
  ARCH="aarch64-unknown-linux-gnu"
  SOLANA_DOWNLOAD_ROOT="https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download"
else
  echo "[monitoring-entrypoint] Unsupported architecture: $ARCH" >&2
  exit 1
fi

# Progress: prepare install directories
echo "[monitoring-entrypoint] Step 3/5: Preparing install directories..."
INSTALL_DIR="/opt/solana/install"
RELEASE_DIR="$INSTALL_DIR/releases/$SOLANA_RELEASE"
ACTIVE_RELEASE="$INSTALL_DIR/active_release"
SOLANA_RELEASE_URL="$SOLANA_DOWNLOAD_ROOT/v${SOLANA_RELEASE}/solana-release-${ARCH}.tar.bz2"

# Progress: install Solana CLI if needed
echo "[monitoring-entrypoint] Step 4/5: Checking Solana CLI installation..."
if ! command -v solana &> /dev/null; then
  echo "[monitoring-entrypoint] Installing bzip2 for archive extraction..."
  sudo apt-get update && sudo apt-get install -y bzip2

  echo "[monitoring-entrypoint] Downloading Solana CLI from $SOLANA_RELEASE_URL ..."
  mkdir -p "$RELEASE_DIR"

  # Download with better error handling
  echo "[monitoring-entrypoint] Creating download directory: $RELEASE_DIR"
  if ! curl -sSfL "$SOLANA_RELEASE_URL" -o "/tmp/solana-release-${ARCH}.tar.bz2"; then
    echo "[monitoring-entrypoint] ERROR: Failed to download Solana CLI from $SOLANA_RELEASE_URL" >&2
    exit 1
  fi

  echo "[monitoring-entrypoint] Extracting Solana CLI to $RELEASE_DIR ..."
  if ! tar -xjf "/tmp/solana-release-${ARCH}.tar.bz2" -C "$RELEASE_DIR"; then
    echo "[monitoring-entrypoint] ERROR: Failed to extract Solana CLI archive" >&2
    exit 1
  fi

  # Clean up downloaded file
  rm -f "/tmp/solana-release-${ARCH}.tar.bz2"

  # Verify extraction
  if [ ! -d "$RELEASE_DIR/solana-release" ]; then
    echo "[monitoring-entrypoint] ERROR: Solana release directory not found after extraction" >&2
    ls -la "$RELEASE_DIR"
    exit 1
  fi

  ln -sf "$RELEASE_DIR/solana-release" "$ACTIVE_RELEASE"
  # Add to PATH for current session
  export PATH="$ACTIVE_RELEASE/bin:$PATH"
  # Add to PATH permanently for ubuntu user
  echo "export PATH=$ACTIVE_RELEASE/bin:"'$PATH' >> /home/ubuntu/.profile

  echo "[monitoring-entrypoint] Solana CLI installed in $INSTALL_DIR."
  echo "[monitoring-entrypoint] Installation verification:"
  ls -la "$RELEASE_DIR/solana-release/"
  echo "[monitoring-entrypoint] Testing solana command:"
  solana --version
else
  echo "[monitoring-entrypoint] Solana CLI is already installed."
fi
# Progress: container ready
echo "[monitoring-entrypoint] Step 5/5: Monitoring container ready."
echo "[monitoring-entrypoint] Solana CLI installation completed successfully."
