#!/bin/bash
# This script builds the Jito-Solana CLI inside a Docker container and uploads it to S3.

if [ -z "${JITO_SOLANA_RELEASE}" ]; then echo "Error: JITO_SOLANA_RELEASE is not set"; exit 1; fi
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then echo "Error: AWS_ACCESS_KEY_ID is not set"; exit 1; fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then echo "Error: AWS_SECRET_ACCESS_KEY is not set"; exit 1; fi
if [ -z "${AWS_REGION}" ]; then echo "Error: AWS_REGION is not set"; exit 1; fi
if [ -z "${BUCKET_NAME}" ]; then echo "Error: BUCKET_NAME is not set"; exit 1; fi

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

pretty_echo  "Installing utilities..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    unzip \
    curl

# install AWS CLI. See https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
pretty_echo "Installing AWS CLI..."
AWS_CLI_INSTALLER_FILENAME= && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) AWS_CLI_INSTALLER_FILENAME='awscli-exe-linux-x86_64.zip';; \
        arm64) AWS_CLI_INSTALLER_FILENAME='awscli-exe-linux-aarch64.zip';; \
        *) echo "unsupported architecture"; exit 1 ;; \
    esac \
    && curl "https://awscli.amazonaws.com/${AWS_CLI_INSTALLER_FILENAME}" -o "awscliv2.zip" \
    && unzip awscliv2.zip > /dev/null 2>&1 && \
    ./aws/install

# check if jito-solana binary is already in the s3 bucket
JITO_TAG="v${JITO_SOLANA_RELEASE}-jito"
BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
JITO_BINARY_S3_KEY="jito-solana/releases/download/${JITO_TAG}/solana-release-$BINARY_NAME"
S3_DOWNLOAD_BASE_URL="https://solv-store.s3.us-east-1.amazonaws.com"

pretty_echo "Checking if Jito-Solana v${JITO_SOLANA_RELEASE}/${ARCH} exists in S3 bucket..."
if [ "${FORCE_UPLOAD:-false}" != "true" ] && aws s3api head-object --bucket "$BUCKET_NAME" --key "$JITO_BINARY_S3_KEY" 2>/dev/null; then
    echo -e "Jito-Solana v${JITO_SOLANA_RELEASE} already exists in S3 bucket.\nDownload at ${BLUE}${S3_DOWNLOAD_BASE_URL}/$JITO_BINARY_S3_KEY${NC}.\nExiting..."
    exit 0
fi

if [ "${FORCE_UPLOAD:-false}" = "true" ]; then
    pretty_echo "FORCE_UPLOAD is set. Will overwrite existing S3 object if present."
fi

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

git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana
git checkout tags/$JITO_TAG
git submodule update --init --recursive

# build
pretty_echo "Building Jito-Solana v${JITO_SOLANA_RELEASE} for architecture: $ARCH"
BUILD_INSTALL_PATH="/tmp/build/jito-solana"

./scripts/cargo-install-all.sh --validator-only "$BUILD_INSTALL_PATH"/solana-release

# verify the build
pretty_echo "Verifying Jito-Solana v${JITO_SOLANA_RELEASE} build..."
"$BUILD_INSTALL_PATH"/solana-release/bin/agave-validator --version

pretty_echo "Build completed successfully!"

# compress the build
pretty_echo "Compressing Jito-Solana v${JITO_SOLANA_RELEASE} build (bzip2)..."
tar -cvjpf "${BINARY_NAME}" -C "$BUILD_INSTALL_PATH" ./solana-release

# upload to S3 using the standalone upload script
BINARY_PATH="$BUILD_INSTALL_PATH/$BINARY_NAME"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
/tmp/upload-solana-binaries-to-s3.sh jito-solana "$JITO_SOLANA_RELEASE" "$BINARY_PATH" "$ARCH"
