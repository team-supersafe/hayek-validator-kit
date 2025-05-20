#!/bin/bash
agave-validator \
    --identity $ALPHA_CANOPY_KEYS_DIR/identity.json \
    --vote-account $VOTE_ACCOUNT_PUBKEY \
    --authorized-voter $ALPHA_CANOPY_KEYS_DIR/staked-identity.json \
    --known-validator $ENTRYPOINT_IDENTITY_PUBKEY \
    --only-known-rpc \
    --log /home/sol/logs/agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --entrypoint gossip-entrypoint:8001 \
    --expected-genesis-hash $EXPECTED_GENESIS_HASH \
    --allow-private-addr \
    --rpc-port 8899 \
    --no-os-network-limits-test \
    --limit-ledger-size 50000000
