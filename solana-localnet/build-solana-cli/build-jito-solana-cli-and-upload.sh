#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <JITO_SOLANA_RELEASE>"
    echo "Example: $0 2.2.20"
    exit 1
fi

JITO_SOLANA_RELEASE=$1
JITO_TAG="v${JITO_SOLANA_RELEASE}-jito"

# Check required environment variables
if [ -z "${SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID}" ]; then
    echo "Error: SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID is not set";
    exit 1;
fi
if [ -z "${SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY}" ]; then
    echo "Error: SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY is not set";
    exit 1;
fi

# Set AWS environment variables
export AWS_ACCESS_KEY_ID=$SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY
export AWS_REGION=us-east-1
export BUCKET_NAME=solv-store

set -euo pipefail

ARCH=$(uname -m)

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

pretty_echo() {
  echo -e "\n\n${YELLOW}$1 =============================================================${NC}\n"
}

pretty_echo "Operating System:"
if command -v lsb_release &> /dev/null; then
    lsb_release -a
else
    echo "OS: $(uname -s) $(uname -r)"
fi
echo "Detected architecture: $ARCH"
echo

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    pretty_echo "Installing AWS CLI..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
        sudo installer -pkg AWSCLIV2.pkg -target /
        rm AWSCLIV2.pkg
    else
        # Linux - try multiple installation methods
        echo "Installing AWS CLI for Linux..."

        # Method 1: Try the official installer
if curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" 2>/dev/null; then
    echo "Downloaded AWS CLI installer..."

    # Install unzip if not available
    if ! command -v unzip &> /dev/null; then
        echo "Installing unzip..."
        sudo apt-get update && sudo apt-get install -y unzip
    fi

    if unzip awscliv2.zip > /dev/null 2>&1; then
        echo "Extracted AWS CLI..."
        if sudo ./aws/install --update; then
            echo "AWS CLI installed successfully"
            rm -rf aws awscliv2.zip
        else
            echo "Failed to install AWS CLI with installer, trying package manager..."
            rm -rf aws awscliv2.zip
            # Method 2: Try package manager
            if command -v apt-get &> /dev/null; then
                sudo apt-get update && sudo apt-get install -y awscli
            elif command -v yum &> /dev/null; then
                sudo yum install -y awscli
            elif command -v dnf &> /dev/null; then
                sudo dnf install -y awscli
            else
                echo "Error: Could not install AWS CLI. Please install it manually."
                exit 1
            fi
        fi
    else
        echo "Failed to extract AWS CLI installer, trying package manager instead..."
        rm -f awscliv2.zip
        # Method 2: Try package manager
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y awscli
        elif command -v yum &> /dev/null; then
            sudo yum install -y awscli
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y awscli
        else
            echo "Error: Could not install AWS CLI. Please install it manually."
            exit 1
        fi
    fi
else
    echo "Failed to download AWS CLI installer, trying package manager..."
    # Method 2: Try package manager
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y awscli
    elif command -v yum &> /dev/null; then
        sudo yum install -y awscli
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y awscli
    else
        echo "Error: Could not install AWS CLI. Please install it manually."
        exit 1
    fi
fi
    fi
fi

# Verify AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI installation failed or not found in PATH"
    exit 1
fi

# check if jito-solana binary is already in the s3 bucket
pretty_echo "Checking if Jito-Solana v${JITO_SOLANA_RELEASE}/${ARCH} exists in S3 bucket..."
BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
JITO_BINARY_S3_KEY="jito-solana/releases/download/${JITO_TAG}/solana-release-$BINARY_NAME"
S3_DOWNLOAD_BASE_URL="https://solv-store.s3.us-east-1.amazonaws.com"

if aws s3api head-object --bucket "$BUCKET_NAME" --key $JITO_BINARY_S3_KEY 2>/dev/null; then
  echo -e "Jito-Solana v${JITO_SOLANA_RELEASE} already exists in S3 bucket.\nDownload at ${BLUE}${S3_DOWNLOAD_BASE_URL}/$JITO_BINARY_S3_KEY${NC}.\n"
  echo "Exiting..."
  exit 0
fi

# Install build dependencies
pretty_echo "Installing build dependencies..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libudev-dev \
    llvm \
    libclang-dev \
    libssl-dev \
    protobuf-compiler \
    cmake \
    git \
    curl \
    wget \
    unzip \
    ca-certificates \
    zlib1g-dev \
    libprotobuf-dev

# Check if Rust is installed
if ! command -v rustc &> /dev/null; then
    pretty_echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Update Rust and add required components
pretty_echo "Updating Rust and adding required components..."
source "$HOME/.cargo/env"
rustup --version
rustup update
rustup component add rustfmt

pretty_echo "Installed software:"
echo "Rust version: $(rustc --version)"
echo "Cargo version: $(cargo --version)"
echo "AWS version: $(aws --version)"

# Clone jito-solana repository with submodules
pretty_echo "Cloning Jito-Solana v${JITO_SOLANA_RELEASE} source with submodules..."
mkdir -p /tmp/build
cd /tmp/build

# Remove existing directory if it exists
if [ -d "jito-solana" ]; then
    rm -rf jito-solana
fi

git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana
git checkout tags/$JITO_TAG
git submodule update --init --recursive

# build
pretty_echo "Building Jito-Solana v${JITO_SOLANA_RELEASE} for architecture: $ARCH"
BUILD_INSTALL_PATH="$HOME/build/jito-solana"

# Ensure the build directory exists
mkdir -p "$BUILD_INSTALL_PATH"

CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only "$BUILD_INSTALL_PATH"

# verify the build
pretty_echo "Verifying Jito-Solana v${JITO_SOLANA_RELEASE} build..."
"$BUILD_INSTALL_PATH"/bin/agave-validator --version

# compress the build
pretty_echo "Compressing Jito-Solana v${JITO_SOLANA_RELEASE} build (bzip2)..."
tar -cvjpf "${BINARY_NAME}" -C "$BUILD_INSTALL_PATH" .

# upload to S3 using the standalone upload script
BINARY_PATH="/tmp/build/jito-solana/$BINARY_NAME"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
"$SCRIPT_DIR/upload-solana-binaries-to-s3.sh" jito-solana "$JITO_SOLANA_RELEASE" "$BINARY_PATH" "$ARCH"

pretty_echo "Build completed successfully!"
