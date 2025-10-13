#!/bin/bash
# monitoring-setup.sh - Install Solana CLI, Grafana and InfluxDB for monitoring container

echo "[monitoring-setup] Starting monitoring tools installation..."

# Detect architecture and set download URL
ARCH="$(uname -m)"
DOWNLOAD_ROOT="https://solv-store.s3.us-east-1.amazonaws.com/agave/releases/download"
case "$ARCH" in
  x86_64)
    ARCH="x86_64-unknown-linux-gnu"
    ;;
  aarch64)
    ARCH="aarch64-unknown-linux-gnu"
    ;;
  *)
    echo "[monitoring-setup] ERROR: Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

# Install Solana CLI if not present
if ! command -v solana &> /dev/null; then
  SOLANA_RELEASE="2.2.20"
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

# Install Grafana if not present
if ! command -v grafana-server &> /dev/null; then
  echo "[monitoring-setup] Installing Grafana..."

  # Install prerequisites
  sudo apt-get install -y apt-transport-https software-properties-common wget gnupg

  # Import GPG key
  sudo mkdir -p /etc/apt/keyrings/
  wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

  # Add stable repository
  echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

  # Update package list and install Grafana OSS
  sudo apt-get update -qq
  sudo apt-get install -y grafana

  # Enable and start Grafana service
  sudo systemctl enable grafana-server
  sudo systemctl start grafana-server

  echo "[monitoring-setup] Grafana installed and started successfully"
else
  echo "[monitoring-setup] Grafana already installed"
fi

# Install InfluxDB if not present
if ! command -v influxd &> /dev/null; then
  echo "[monitoring-setup] Installing InfluxDB..."

  # Download and verify InfluxData repository key
  wget -q https://repos.influxdata.com/influxdata-archive_compat.key
  echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null

  # Add InfluxData repository
  echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

  # Update package lists and install InfluxDB
  sudo apt-get update -qq
  sudo apt-get install -y influxdb

  # Enable and start InfluxDB service
  sudo systemctl enable influxdb
  sudo systemctl start influxdb

  # Clean up downloaded key file
  rm -f influxdata-archive_compat.key

  echo "[monitoring-setup] InfluxDB installed and started successfully"
else
  echo "[monitoring-setup] InfluxDB already installed"
fi

echo "[monitoring-setup] Monitoring container ready."
