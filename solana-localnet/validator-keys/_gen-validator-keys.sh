#!/bin/bash
set -e

# Generate Solana keypairs

# validator identity
solana-keygen grind --starts-with Z1:1
mv Z1*.json staked-identity.json
touch staked-identity-"$(solana-keygen pubkey staked-identity.json)" # handy for fast checking the pubkey

# vote account
solana-keygen grind --starts-with Z2:1
mv Z2*.json vote-account.json
touch vote-account-"$(solana-keygen pubkey vote-account.json)" # handy for fast checking the pubkey

# stake account
solana-keygen grind --starts-with Z3:1
mv Z3*.json stake-account.json
touch stake-account-"$(solana-keygen pubkey stake-account.json)" # handy for fast checking the pubkey

# authorized withdrawer
solana-keygen grind --starts-with Z4:1
mv Z4*.json authorized-withdrawer.json
touch authorized-withdrawer-"$(solana-keygen pubkey authorized-withdrawer.json)" # handy for fast checking the pubkey

# jito relayer block engine
solana-keygen grind --starts-with Z5:1
mv Z5*.json jito-relayer-block-engine-private.json
touch jito-relayer-block-engine-"$(solana-keygen pubkey jito-relayer-block-engine-private.json)" # handy for fast checking the pubkey

# Generate Jito relayer comms keypair
openssl genrsa --out jito-relayer-comms-private.pem 2048
openssl rsa --in jito-relayer-comms-private.pem --pubout --out jito-relayer-comms-public.pem

echo "All validator keys have been generated."