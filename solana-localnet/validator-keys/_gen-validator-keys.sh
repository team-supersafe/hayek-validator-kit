#!/bin/bash
set -e

# Generate Solana keypairs only if they do not already exist

# validator identity
if [ ! -f staked-identity.json ]; then
  solana-keygen grind --starts-with Z1:1
  mv Z1*.json staked-identity.json
  touch staked-identity-"$(solana-keygen pubkey staked-identity.json)" # handy for fast checking the pubkey
fi

# vote account
if [ ! -f vote-account.json ]; then
  solana-keygen grind --starts-with Z2:1
  mv Z2*.json vote-account.json
  touch vote-account-"$(solana-keygen pubkey vote-account.json)" # handy for fast checking the pubkey
fi

# stake account
if [ ! -f stake-account.json ]; then
  solana-keygen grind --starts-with Z3:1
  mv Z3*.json stake-account.json
  touch stake-account-"$(solana-keygen pubkey stake-account.json)" # handy for fast checking the pubkey
fi

# authorized withdrawer
if [ ! -f authorized-withdrawer.json ]; then
  solana-keygen grind --starts-with Z4:1
  mv Z4*.json authorized-withdrawer.json
  touch authorized-withdrawer-"$(solana-keygen pubkey authorized-withdrawer.json)" # handy for fast checking the pubkey
fi

# jito relayer block engine
if [ ! -f jito-relayer-block-engine-private.json ]; then
  solana-keygen grind --starts-with Z5:1
  mv Z5*.json jito-relayer-block-engine-private.json
  touch jito-relayer-block-engine-"$(solana-keygen pubkey jito-relayer-block-engine-private.json)" # handy for fast checking the pubkey
fi

# Generate Jito relayer comms keypair only if private key does not exist
if [ ! -f jito-relayer-comms-private.pem ]; then
  openssl genrsa --out jito-relayer-comms-private.pem 2048
  openssl rsa --in jito-relayer-comms-private.pem --pubout --out jito-relayer-comms-public.pem
fi

echo "All validator keys have been generated."