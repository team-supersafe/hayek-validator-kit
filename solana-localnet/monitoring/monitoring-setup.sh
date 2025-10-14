#!/bin/bash
# monitoring-setup.sh - Grafana and InfluxDB for monitoring container

echo "[monitoring-setup] Starting monitoring tools installation..."

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

  # Verify the key's checksum
  echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c
  if [ $? -ne 0 ]; then
    echo "[monitoring-setup] ERROR: Checksum verification for InfluxDB key failed."
    exit 1
  fi

  # Convert the key to GPG format
  cat influxdata-archive_compat.key | gpg --dearmor > influxdata-archive_compat.gpg
  if [ $? -ne 0 ]; then
    echo "[monitoring-setup] ERROR: GPG conversion for InfluxDB key failed."
    exit 1
  fi

  # Move the GPG key to the trusted location
  sudo mv influxdata-archive_compat.gpg /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg
  if [ $? -ne 0 ]; then
    echo "[monitoring-setup] ERROR: Failed to move GPG key to /etc/apt/trusted.gpg.d."
    exit 1
  fi

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
