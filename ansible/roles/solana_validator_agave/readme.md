# Running a Validator with the Agave-Solana Client (Anza)

ssh into your validator machine
```sh
ssh -F /dev/null -i ~/.ssh/id_ed25519 sol@$VALIDATOR_HOSTNAME -p $VALIDATOR_SSH_PORT
```

## Install the Solana CLI on validator machine (build from source)

For the remote validator machine is better to build from software
 - this makes sure the binary that you are running is built from the actual Solana source code
 - this can add performance improvement because is build for our specific hardware and not for generic setup
 - See https://docs.anza.xyz/cli/install#build-from-source

1. Install prerequisites
```sh
# Rust compiler
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
# Press 1 (default install)

. "$HOME/.cargo/env"
# or run `exit` to close the session and ssh again to restart the shell with `$HOME/.cargo/bin` added to $PATH and then ssh back to validator machine
# ssh -F /dev/null -i ~/.ssh/id_ed25519 sol@$VALIDATOR_HOSTNAME -p $VALIDATOR_SSH_PORT

# build dependencies (needs sudo)
rustup update
sudo apt-get update
sudo apt-get install \
    build-essential \
    pkg-config \
    libudev-dev llvm libclang-dev \
    protobuf-compiler
```

2. Select the Testnet/Mainnet CLI version to install
To know what is the latest version you can go to Discord announcements under validators:
 - [testnet-announcements](https://discord.com/channels/428295358100013066/594138785558691840)
 - [mb-announcements](https://discord.com/channels/428295358100013066/669406841830244375)

Then set the version as an environment varibale for building

```sh
export SOLANA_RELEASE=2.1.13
```

3. Build from Source

```sh
# prepare dirs
mkdir -p ~/.local/share/solana/install/releases
mkdir -p ~/build
cd ~/build

# download and extract the release archive
curl -L -O "https://github.com/anza-xyz/agave/archive/refs/tags/v${SOLANA_RELEASE}.tar.gz"
tar -xvzf "v${SOLANA_RELEASE}.tar.gz"

# build
cd "agave-${SOLANA_RELEASE}"
# ./scripts/cargo-install-all.sh ~/.local/share/solana/install/releases/"$SOLANA_RELEASE"
./scripts/cargo-install-all.sh .
```

The above will compile the source code and create the following:
  - /home/sol/build/agave-${SOLANA_RELEASE}/bin
  - /home/sol/build/agave-${SOLANA_RELEASE}/.crates.toml
  - /home/sol/build/agave-${SOLANA_RELEASE}/.crates2.json

```sh
tr ':' '\n' <<< "$PATH"
# /home/ubuntu/.local/share/solana/install/active_release/bin
# /home/ubuntu/.cargo/bin
# /usr/local/sbin
# /usr/local/bin
# /usr/sbin
# /usr/bin
# /sbin
# /bin
# /usr/games
# /usr/local/games
# /snap/bin
```

```sh
tr ':' '\n' <<< "$PATH"
# /home/ubuntu/build/agave-2.1.16/bin
# /home/ubuntu/.local/share/solana/install/active_release/bin
# /home/ubuntu/.cargo/bin
# /usr/local/sbin
# /usr/local/bin
# /usr/sbin
# /usr/bin
# /sbin
# /bin
# /usr/games
# /usr/local/games
# /snap/bin
```

```sh
# before
ls -al ~/.local/share/solana/install/
active_release -> /home/ubuntu/.local/share/solana/install/releases/2.1.14/solana-release/
releases/
ls -al ~/.local/share/solana/install/releases
# 2.1.14
ls -al ~/.local/share/solana/install/releases/2.1.14/solana-release/
# .crates.toml
# .crates2.json
# bin
# version.yml

# after
ls -al ~/.local/share/solana/install/

ls -al ~/.local/share/solana/install/releases

ls -al ~/.local/share/solana/install/releases/2.1.16/solana-release/
```

As an alternative to building, you can also download prebuilt binaries
- See https://docs.anza.xyz/cli/install#download-prebuilt-binaries
```sh
curl -L -O "https://github.com/anza-xyz/agave/releases/download/v${SOLANA_RELEASE}/solana-release-x86_64-unknown-linux-gnu.tar.bz2"
tar -xvjf "solana-release-x86_64-unknown-linux-gnu.tar.bz2"
```

4. Update active release link after install/update

```sh
# update active release link
unlink ~/.local/share/solana/install/active_release
ln -sf ~/.local/share/solana/install/releases/"$SOLANA_RELEASE" ~/.local/share/solana/install/active_release
export PATH=~/.local/share/solana/install/active_release/bin:$PATH

# check installation
which solana
# /home/sol/.local/share/solana/install/active_release/bin/solana

solana --version
# solana-cli <SOLANA_RELEASE> (src:12345678; feat:1234567890, client:Agave)

# cleanup
cd ~
rm -r ~/build/"v${SOLANA_RELEASE}.tar.gz"
rm -r ~/build/"agave-${SOLANA_RELEASE}"
```

To add solana cli to your user's PATH, edit `~/.profile` to add the line

```sh
echo 'export PATH=~/.local/share/solana/install/active_release/bin:$PATH' >> ~/.profile
~
```

## Create Validator Startup Script

1. Create script file and make executable

```sh
mkdir -p /home/sol/bin
mkdir -p /home/sol/logs

# testnet
touch /home/sol/bin/validator-testnet.sh
chmod +x /home/sol/bin/validator-testnet.sh
nano /home/sol/bin/validator-testnet.sh

# mainnet
touch /home/sol/bin/validator-mainnet.sh
chmod +x /home/sol/bin/validator-mainnet.sh
nano /home/sol/bin/validator-mainnet.sh
```

2. Add script content

#### Testnet Arguments

```sh
#!/bin/bash
export SOLANA_METRICS_CONFIG="host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
exec agave-validator \
    --identity /home/sol/keys-testnet/staked-identity.json \
    --vote-account <vote-account-pubkey> \
    --known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \
    --known-validator dDzy5SR3AXdYWVqbDEkVFdvSPCtS9ihF5kJkHCtXoFs \
    --known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \
    --known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \
    --known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \
    --only-known-rpc \
    --log /home/sol/logs/agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --minimal-snapshot-download-speed \
    --rpc-port 8899 \
    --dynamic-port-range 8000-8020 \
    --entrypoint entrypoint.testnet.solana.com:8001 \
    --entrypoint entrypoint2.testnet.solana.com:8001 \
    --entrypoint entrypoint3.testnet.solana.com:8001 \
    --expected-genesis-hash 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size \
    --gossip-port 8001 \
    --private-rpc \
    --block-verification-method=unified-scheduler
```

#### Mainnet Arguments
TODO

NOTES:
  - Ensure that the `exec` command is used to start the validator process (i.e. "exec agave-validator ..."). This is important because without it, logrotate will end up killing the validator every time the logs are rotated.

  - For `--vote-account` you can pass the public key so you don't have to copy the keypair

  - After the first run, a snapshot will be downloaded and then (99% of the time) you want to add the `--no-snapshot-fetch` flag. Ideally, you should never have to get a snapshot after the first time you start your validator and you get a snapshot from one of owr known validators. See https://youtu.be/nY2SFjaDXHw?si=D5Ia7uhUoFNp-dvX&t=1424

  - Use `--no-port-check` to skip network accessibility checks

  - Private binds the rpc to 127.0.0.1 so nobody can connect to the RPC outside of localhost
https://discord.com/channels/428295358100013066/1187805174803210341/1339467402215161916

  - Don't forget the shebang (`#!/bin/bash`) at the begining of the scirpt

3. Start the validator

The script should execute the agave-validator process

```sh
/home/sol/bin/validator-testnet.sh
```

To exit `agave-validator`, run

```sh
agave-validator --ledger /mnt/ledger exit --min-idle-time 0 # --max-delinquent-stake 10
```

NOTES:
  - Avoid stopping your validator when it is in the middle of downloading a snapshot.
  Flags `--max-delinquent-stake` and `--min-idle-time` are important if you are in the leader schedule
  - The `exit` sub-command works well with `systemd` so if the sol service is configured, it will restart automatically after exiting. See https://youtu.be/nY2SFjaDXHw?si=NDo533KWGXPdas6Y&t=2953

4. Add the `--no-snapshot-fetch` to the validator script

After you know your validator es running fine and catching up and already downloaded a snapshot, add the `--no-snapshot-fetch` to the validator script for the next time it starts. 

There are times though, when you want to NOT use `--no-snapshot-fetch`, e.g. if your validator crashes and you fall too far behind then there is usually no way to catch up because you are too far behind the network to make up the progress that the rest of the cluster made, so this is when you want to remove the `--no-snapshot-fetch` flag. See https://youtu.be/HKR5dn5CSZo?si=zrb-dT6NMlgKWXCl&t=1933.

Typically if you are a few thousand slots behind or more, unless you have a really good hardware, it might not be feasible to catch up. See https://youtu.be/HKR5dn5CSZo?si=F19E4xtqqKgd7kUm&t=1974.

Snapshot finder tool: https://github.com/c29r3/solana-snapshot-finder
This is a python script that tests a bunch of RPC endpoints that are open to check what the best download speed is and then downloads the snapshot from that one.


### What to do if you can't catch up
  - See https://youtu.be/HKR5dn5CSZo?si=Kmul5ry-tsstZ0QL&t=1958
  - Wait! Catchup rate is variable and l've seen it improve very quickly after falling for a while
  - Remove -no-snapshot-fetch and download a new snapshot (you will have a hole in your validator's ledger)
  - Manually download a snapshot https://github.com/c29r3/solana-snapshot-finder is popular

### Possible Reasons for falling behind (can't catch up)
  - See https://youtu.be/HKR5dn5CSZo?si=xvu47Bcre3L3jF2f&t=2120
  - Snapshots you are downloading are too old (try using known validator, increase minimal download speed, snapshot finder)
  - If snapshot is good, but you still can't catch up, it's likely a hardware perf issue 
    - Check CPU, Thermal Design Power (TDP), NVMe drives, IOPS, Network, etc.
    - Try another server for a month?
    - Consider upgrading


### Update command line arguments without restarting the validator

```sh
agave-validator help
# SUBCOMMANDS:
# --> authorized-voter           Adjust the validator authorized voters
#     contact-info               Display the validator's contact info
#     exit                       Send an exit request to the validator
#     help                       Prints this message or the help of the given subcommand(s)
#     init                       Initialize the ledger directory then exit
#     monitor                    Monitor the validator
# --> plugin                     Manage and view geyser plugins
# --> repair-shred-from-peer     Request a repair from the specified validator
# --> repair-whitelist           Manage the validator's repair protocol whitelist
#     run                        Run the validator
# --> set-identity               Set the validator identity
# --> set-log-filter             Adjust the validator log filter
# --> set-public-address         Specify addresses to advertise in gossip
# --> staked-nodes-overrides     Overrides stakes of specific node identities.
# --> wait-for-restart-window    Monitor the validator for a good time to restart
```

### Identity Hotswap
- TODO
- See https://github.com/mvines/validator-Identity-transition-demo
- See https://jito-foundation.gitbook.io/mev/jito-solana/command-line-arguments#changing-jito-specific-config




### Validator script examples

```sh
# https://discord.com/channels/428295358100013066/837340113067049050/1335719582207315999
/app/solana/bin/agave-validator \
  --identity /app/solana/validator-keypair.json \
  --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
  --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
  --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
  --known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
  --only-known-rpc \
  --full-rpc-api \
  --no-voting \
  --ledger /data/atlas-sol-mainnet-node-data/ledger \
  --accounts /data/atlas-sol-mainnet-node-data/accounts \
  --log /data/logs/solana.logs \
  --rpc-port 8899 \
  --rpc-bind-address 0.0.0.0 \
  --private-rpc \
  --dynamic-port-range 8020-8034 \
  --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
  --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
  --wal-recovery-mode skip_any_corrupted_record \
  --limit-ledger-size 2000000000


# https://discord.com/channels/428295358100013066/560174212967432193/1264221841053057075
BLOCK_ENGINE_URL=https://ny.mainnet.block-engine.jito.wtf
SHRED_RECEIVER_ADDR=141.98.216.96:1002
RELAYER_URL=http://ny.mainnet.relayer.jito.wtf:8100
exec solana-validator \
    --identity ~/validator-keypair.json \
    --vote-account [redacted] \
    --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
    --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
    --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
    --known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --known-validator [redacted] \
    --only-known-rpc \
    --log /home/sol/logs/agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --rpc-port 8899 \
    --private-rpc \
    --dynamic-port-range 8000-10000 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size \
    --tip-payment-program-pubkey T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt \
    --tip-distribution-program-pubkey 4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7 \
    --merkle-root-upload-authority GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib \
    --commission-bps 0 \
    --relayer-url ${RELAYER_URL} \
    --block-engine-url ${BLOCK_ENGINE_URL} \
    --shred-receiver-address ${SHRED_RECEIVER_ADDR}


# https://discord.com/channels/428295358100013066/837340113067049050/1278672952895868990
export SOLANA_RAYON_THREADS=32

exec agave-validator \
    --no-snapshot-fetch \
    --log /mnt/snapshots/logs/solana-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --accounts-hash-cache-path /mnt/snapshots/accounts_hash_cache \
    --rpc-port 8899 \
    --private-rpc \
    --no-voting \
    --full-rpc-api \
    --dynamic-port-range 8000-8040 \
    --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
    --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
    --wal-recovery-mode skip_any_corrupted_record \
    --limit-ledger-size 100000000 \
    --snapshots /mnt/snapshots/snap \
    --use-snapshot-archives-at-startup when-newest \
    --expected-shred-version 50093 \
    --rpc-bind-address 0.0.0.0 \
    --no-skip-initial-accounts-db-clean \
    --account-index program-id spl-token-owner spl-token-mint \
    --geyser-plugin-config ~/yellowstone-config/config.json
```
