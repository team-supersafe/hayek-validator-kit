#!/bin/bash
set -e

# Generate Solana keypairs for each required key file
solana-keygen grind -s --no-bip39-passphrase --starts-with temp:1 -o staked-identity.json
solana-keygen grind -s --no-bip39-passphrase --starts-with temp:1 -o vote-account.json
solana-keygen grind -s --no-bip39-passphrase --starts-with temp:1 -o stake-account.json
solana-keygen grind -s --no-bip39-passphrase --starts-with temp:1 -o authorized-withdrawer.json
solana-keygen grind -s --no-bip39-passphrase --starts-with temp:1 -o jito-relayer-block-engine-private.json

# Generate Jito relayer comms keypair
openssl genrsa --out jito-relayer-comms-private.pem 2048
openssl rsa --in jito-relayer-comms-private.pem --pubout --out jito-relayer-comms-public.pem

echo "All validator keys have been generated."