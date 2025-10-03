#!/bin/bash

if [ $# -lt 3 ]; then
    echo "Usage: $0 <BINARY_TYPE> <VERSION> <BINARY_PATH> [ARCH]"
    echo ""
    echo "BINARY_TYPE options:"
    echo "  solana-cli    - Standard Solana CLI binaries"
    echo "  jito-solana   - Jito-Solana binaries"
    echo "  jito-relayer  - Jito Relayer binaries"
    echo ""
    echo "Examples:"
    echo "  $0 solana-cli 1.18.0 /tmp/build/agave-1.18.0/solana-release-x86_64-unknown-linux-gnu.tar.bz2"
    echo "  $0 jito-solana 2.2.20 /tmp/build/jito-solana/x86_64-unknown-linux-gnu.tar.bz2"
    echo "  $0 jito-relayer 1.0.0 /tmp/build/jito-relayer/x86_64-unknown-linux-gnu.tar.bz2"
    exit 1
fi

BINARY_TYPE=$1
VERSION=$2
BINARY_PATH=$3
ARCH=${4:-$(uname -m)}

# Check required environment variables
if [ -z "${SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID}" ]; then
    echo "Error: SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID is not set"
    exit 1
fi
if [ -z "${SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY}" ]; then
    echo "Error: SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY is not set"
    exit 1
fi

# Validate binary type
case "$BINARY_TYPE" in
    solana-cli|jito-solana|jito-relayer)
        ;;
    *)
        echo "Error: Invalid BINARY_TYPE '$BINARY_TYPE'. Must be one of: solana-cli, jito-solana, jito-relayer"
        exit 1
        ;;
esac

# Validate binary path exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary file does not exist: $BINARY_PATH"
    exit 1
fi

# Set AWS environment variables
export AWS_ACCESS_KEY_ID=$SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY
export AWS_REGION=us-east-1
export BUCKET_NAME=solv-store

set -euo pipefail

# Color codes
RED='\033[0;31m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

pretty_echo() {
  echo -e "\n\n${YELLOW}$1 =============================================================${NC}\n"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Generate S3 key based on binary type
case "$BINARY_TYPE" in
    solana-cli)
        BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
        S3_KEY="agave/releases/download/v${VERSION}/solana-release-$BINARY_NAME"
        DISPLAY_NAME="Solana CLI"
        ;;
    jito-solana)
        BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
        JITO_TAG="v${VERSION}-jito"
        S3_KEY="jito-solana/releases/download/${JITO_TAG}/solana-release-$BINARY_NAME"
        DISPLAY_NAME="Jito-Solana"
        ;;
    jito-relayer)
        BINARY_NAME="${ARCH}-unknown-linux-gnu.tar.bz2"
        S3_KEY="jito-relayer/releases/download/v${VERSION}/jito-relayer-$BINARY_NAME"
        DISPLAY_NAME="Jito Relayer"
        ;;
esac

S3_DOWNLOAD_BASE_URL="https://solv-store.s3.us-east-1.amazonaws.com"

# Check if binary already exists in S3 bucket
pretty_echo "Checking if ${DISPLAY_NAME} v${VERSION}/${ARCH} exists in S3 bucket..."

# Check if --force-upload was NOT provided AND the file exists in S3
if [ "${FORCE_UPLOAD:-false}" != "true" ] && aws s3api head-object --bucket "$BUCKET_NAME" --key "$S3_KEY" 2>/dev/null; then
    # File exists and we are NOT forcing an upload
    echo -e "${DISPLAY_NAME} v${VERSION} already exists in S3 bucket.\nDownload at ${BLUE}${S3_DOWNLOAD_BASE_URL}/$S3_KEY${NC}.\n"
    echo "Exiting..."
    exit 0
fi

if [ "${FORCE_UPLOAD:-false}" = "true" ]; then
    pretty_echo "Force upload requested. Overwriting existing S3 object if it exists."
fi

# Upload to S3
pretty_echo "Uploading ${DISPLAY_NAME} v${VERSION} build to S3..."
aws s3 cp "$BINARY_PATH" "s3://$BUCKET_NAME/$S3_KEY"

pretty_echo "Upload completed successfully!"
echo -e "Download URL: ${BLUE}${S3_DOWNLOAD_BASE_URL}/$S3_KEY${NC}"
