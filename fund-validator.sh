#!/bin/bash

# Check if validator name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <validator_name>"
    echo "Example: $0 penny"
    exit 1
fi

VALIDATOR_NAME="$1"
CLUSTER_RPC=http://localhost:8899
solana config set --url $CLUSTER_RPC
KEYS_DIR=".validator-keys/$VALIDATOR_NAME"

# Check if keys directory exists
if [ ! -d "$HOME/$KEYS_DIR" ]; then
    echo "Error: Keys directory $HOME/$KEYS_DIR does not exist"
    echo "Please ensure the validator keys are properly set up first"
    exit 1
fi

cd ~/$KEYS_DIR

# Check if required keypair files exist with correct naming
echo "Validating required keypair files..."

if [ ! -f "primary-target-identity.json" ]; then
    echo "Error: primary-target-identity.json not found"
    echo "Please ensure the validator identity keypair is named 'primary-target-identity.json'"
    exit 1
fi

if [ ! -f "authorized-withdrawer.json" ]; then
    echo "Error: authorized-withdrawer.json not found"
    echo "Please ensure the authorized withdrawer keypair is named 'authorized-withdrawer.json'"
    exit 1
fi

echo "All required keypair files found with correct naming convention."

echo "Funding validator: $VALIDATOR_NAME"
echo "Working directory: $HOME/$KEYS_DIR"

# Fund primary identity and create vote account
echo "Funding primary identity with 42 SOL..."
solana -u $CLUSTER_RPC --keypair primary-target-identity.json airdrop 42

echo "Creating vote account..."
solana -u $CLUSTER_RPC create-vote-account vote-account.json primary-target-identity.json authorized-withdrawer.json

echo "Validator funding completed successfully!"
echo "You can now proceed with validator installation and startup." 