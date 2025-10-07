#!/bin/bash
# This script builds the Solana CLI inside a Docker container and uploads it to S3.

if [ -z "${SOLANA_RELEASE}" ]; then echo "Error: SOLANA_RELEASE is not set"; exit 1; fi
if [ -z "${AWS_ACCESS_KEY_ID}" ]; then echo "Error: AWS_ACCESS_KEY_ID is not set"; exit 1; fi
if [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then echo "Error: AWS_SECRET_ACCESS_KEY is not set"; exit 1; fi
if [ -z "${AWS_REGION}" ]; then echo "Error: AWS_REGION is not set"; exit 1; fi
if [ -z "${BUCKET_NAME}" ]; then echo "Error: BUCKET_NAME is not set"; exit 1; fi

set -euo pipefail
# set -x

ARCH=$(uname -m)

RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

pretty_echo() {
  echo -e "\n\n${YELLOW}$1 =============================================================${NC}\n"
}

pretty_echo "Operating System:"
lsb_release -a
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

# check if solana cli is already in the s3 bucket
BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
SOLANA_BINARY_S3_KEY="agave/releases/download/v${SOLANA_RELEASE}/solana-release-$BINARY_NAME"
S3_DOWNLOAD_BASE_URL="https://solv-store.s3.us-east-1.amazonaws.com"

pretty_echo "Checking if Solana CLI v${SOLANA_RELEASE}/${ARCH} exists in S3 bucket..."
if [ "${FORCE_UPLOAD:-false}" != "true" ] && aws s3api head-object --bucket "$BUCKET_NAME" --key $SOLANA_BINARY_S3_KEY 2>/dev/null; then
  echo -e "Solana CLI v${SOLANA_RELEASE} already exists in S3 bucket.\nDownload at ${BLUE}${S3_DOWNLOAD_BASE_URL}/$SOLANA_BINARY_S3_KEY${NC}.\nExiting..."
  exit 0
fi

if [ "${FORCE_UPLOAD:-false}" = "true" ]; then
    pretty_echo "FORCE_UPLOAD is set. Will overwrite existing S3 object if present."
fi

pretty_echo  "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"
rustup --version
rustup update

pretty_echo  "Installing dependencies..."
sudo apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev libssl-dev \
    protobuf-compiler

pretty_echo "Installed software:"
echo "Rust version: $(rustc --version)"
echo "Cargo version: $(cargo --version)"
echo "AWS version: $(aws --version)"

# download and extract the release archive
pretty_echo "Downloading Solana CLI v${SOLANA_RELEASE} source..."
mkdir -p /tmp/build
cd /tmp/build
curl -L -O "https://github.com/anza-xyz/agave/archive/refs/tags/v${SOLANA_RELEASE}.tar.gz"
echo
tar -xvzf "v${SOLANA_RELEASE}.tar.gz" > /dev/null 2>&1

# build
pretty_echo "Building Solana CLI v${SOLANA_RELEASE} for architecture: $ARCH"
cd "agave-${SOLANA_RELEASE}"
./scripts/cargo-install-all.sh ./solana-release

# verify the build
pretty_echo "Verifying Solana CLI v${SOLANA_RELEASE} build..."
/tmp/build/agave-${SOLANA_RELEASE}/solana-release/bin/solana --version

pretty_echo "Build completed successfully!"

# compress the build
pretty_echo "Compressing Solana CLI v${SOLANA_RELEASE} build (gzip)..."
tar -cvjpf "${BINARY_NAME}" -C /tmp/build/agave-${SOLANA_RELEASE} ./solana-release

# upload to S3 using the standalone upload script
BINARY_PATH="/tmp/build/agave-${SOLANA_RELEASE}/$BINARY_NAME"
# Use absolute path for the upload script inside Docker
/tmp/upload-solana-binaries-to-s3.sh solana-cli "$SOLANA_RELEASE" "$BINARY_PATH" "$ARCH"
