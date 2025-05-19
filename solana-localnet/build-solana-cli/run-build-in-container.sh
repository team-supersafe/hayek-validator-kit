#!/bin/bash

docker run --rm -it \
  -v ./build-solana-cli-and-upload-to-s3.sh:/tmp/build-solana-cli-and-upload-to-s3.sh \
  -e SOLANA_RELEASE=$1 \
  -e AWS_ACCESS_KEY_ID=$SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID \
  -e AWS_ACCESS_KEY_SECRET=$SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_SECRET \
  -e AWS_REGION=us-east-1 \
  -e BUCKET_NAME=solv-store \
  solana-localnet-validator \
  bash -c "chmod +x /tmp/build-solana-cli-and-upload-to-s3.sh && /tmp/build-solana-cli-and-upload-to-s3.sh"