#!/bin/bash

VOTE_ACCOUNT_PUBKEY=
KNOWN_VALIDATOR_PUBKEY=
EXPECTED_GENESIS_HASH=
KEYS_DIR=~/keys/validator-localnet
agave-validator \
    --identity $KEYS_DIR/identity.json \
    --vote-account $VOTE_ACCOUNT_PUBKEY \
    --authorized-voter $KEYS_DIR/staked-identity.json \
    --known-validator $KNOWN_VALIDATOR_PUBKEY \
    --only-known-rpc \
    --log /home/sol/logs/agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --entrypoint entrypoint:8001 \
    --expected-genesis-hash $EXPECTED_GENESIS_HASH \
    --allow-private-addr \
    --rpc-port 8899 \
    --no-os-network-limits-test \
    --limit-ledger-size 50000000