#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Usage: $0 <BINARY_TYPE> <VERSION>"
    echo ""
    echo "BINARY_TYPE options:"
    echo "  agave        - Standard Solana CLI (Agave)"
    echo "  jito-solana  - Jito-Solana CLI"
    echo ""
    echo "Examples:"
    echo "  $0 agave 1.18.0"
    echo "  $0 jito-solana 2.2.20"
    exit 1
fi

BINARY_TYPE=$1
VERSION=$2

# Validate binary type
case "$BINARY_TYPE" in
    agave|jito-solana)
        ;;
    *)
        echo "Error: Invalid BINARY_TYPE '$BINARY_TYPE'. Must be one of: agave, jito-solana"
        exit 1
        ;;
esac

# Set script path based on binary type
case "$BINARY_TYPE" in
    agave)
        SCRIPT_NAME="build-solana-cli-and-upload-to-s3.sh"
        ;;
    jito-solana)
        SCRIPT_NAME="build-jito-solana-cli-and-upload.sh"
        ;;
esac

# Check if the script exists
if [ ! -f "./$SCRIPT_NAME" ]; then
    echo "Error: Script $SCRIPT_NAME not found in current directory"
    exit 1
fi

# Set environment variables based on binary type
if [ "$BINARY_TYPE" = "agave" ]; then
    ENV_VAR_NAME="SOLANA_RELEASE"
else
    ENV_VAR_NAME="JITO_SOLANA_RELEASE"
fi

docker run --rm -it \
  --name solana-binary-building-from-source \
  -v "./$SCRIPT_NAME:/tmp/$SCRIPT_NAME" \
  -v "./upload-solana-binaries-to-s3.sh:/tmp/upload-solana-binaries-to-s3.sh" \
  -e $ENV_VAR_NAME=$VERSION \
  -e AWS_ACCESS_KEY_ID=$SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY \
  -e AWS_REGION=us-east-1 \
  -e BUCKET_NAME=solv-store \
  solana-localnet-validator \
  bash -c "chmod +x /tmp/$SCRIPT_NAME /tmp/upload-solana-binaries-to-s3.sh && /tmp/$SCRIPT_NAME"
