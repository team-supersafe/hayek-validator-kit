#!/bin/bash

set -e

# Generate primary target identity
if [ ! -f primary-target-identity.json ]; then
    solana-keygen new -s --no-bip39-passphrase -o primary-target-identity.json
    mv Z1*.json primary-target-identity.json
    touch primary-target-identity-"$(solana-keygen pubkey primary-target-identity.json)" # handy for fast checking the pubkey
fi

# Generate hot spare identity
if [ ! -f hot-spare-identity.json ]; then
    solana-keygen new -s --no-bip39-passphrase -o hot-spare-identity.json
    touch hot-spare-identity-"$(solana-keygen pubkey hot-spare-identity.json)" # handy for fast checking the pubkey
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
if [ ! -f jito-relayer-block-eng.json ]; then
  solana-keygen grind --starts-with Z5:1
  mv Z5*.json jito-relayer-block-eng.json
  touch jito-relayer-block-engine-"$(solana-keygen pubkey jito-relayer-block-eng.json)" # handy for fast checking the pubkey
fi

# Generate Jito relayer comms keypair only if private key does not exist
if [ ! -f jito-relayer-comms-pvt.pem ]; then
  openssl genrsa --out jito-relayer-comms-pvt.pem 2048
  openssl rsa --in jito-relayer-comms-pvt.pem --pubout --out jito-relayer-comms-pub.pem
fi

echo "Validator keypairs generated successfully!"
