# Jito-Solana Client (MEV)

## Table of Contents
- [JITO-SOLANA CLIENT (MEVs)](#jito-solana-client-mevs)
- [SETUP JITO-SOLANA VALIDATOR CLIENT](#setup-jito-solana-validator-client)
- [MONITORING](#monitoring)


## Jito Official Links from Discord
### Jito Developers Official Links
Jito Platform:
  - Jito Staking App: https://jito.network/staking/
  - Jito Governance Realms: https://gov.jito.network/dao/Jito
  - Jito Discussion Forum: https://forum.jito.network/
  - Jito Documentation: https://www.jito.network/docs/jitosol/introduction-to-jito/

Jito Contracts:
  - Jito Staked SOL (JitoSOL) Contract: https://solscan.io/token/J1toso1uCk3RLmjorhTtrVwY9HJ7X8V9yYac6Y7kGCPn
  - Jito (JTO) Contract: https://solscan.io/token/jtojtomepa8beP8AuQc6eXt5FriJwfFMwQx2v2f9mCL

Social Media:
  - Jito Twitter: https://twitter.com/jito_sol
  - Jito Labs Twitter: https://twitter.com/jito_labs

For Validators:
  - MEV Documentation: https://jito-foundation.gitbook.io/mev/jito-solana/features
  - Jito Repository: https://github.com/jito-foundation/jito-solana
  - Validator Dashboard: https://jito.retool.com/embedded/public/3557dd68-f772-4f4f-8a7b-f479941dba02

For Searchers:
  - Jito Searcher Docs: https://docs.jito.wtf/
  - Jito Labs/Searcher Examples: https://github.com/jito-labs/searcher-examples
  - Jito MEV Dashboard: https://explorer.jito.wtf/bundle-overview
  - Block Engine System Announcements: https://t.me/+Kg-WnMfiQJAwZjQx

### Jito Community Official Links from Discord
  - See https://discord.com/channels/1250501830425710750/1327036639733616711/1327038798462455840
FOR VALIDATORS & SEARCHERS

Technical Support:
  - Jito Developer Discord: https://discord.gg/jito

Validator Information:
  - MEV Documentation: https://jito-foundation.gitbook.io/mev/jito-solana/features
  - Jito Repository: https://github.com/jito-foundation/jito-solana
  - Validator Dashboard: https://jito.retool.com/embedded/public/3557dd68-f772-4f4f-8a7b-f479941dba02


Searcher Information:
  - Jito Searcher Docs: https://docs.jito.wtf/
  - Jito Labs/Searcher Examples: https://github.com/jito-labs/searcher-examples
  - Jito MEV Dashboard: https://explorer.jito.wtf/bundle-overview
  - Block Engine System Announcements: https://t.me/+Kg-WnMfiQJAwZjQx


## Install Jito-Solana CLI on validator machine (build from source)
- See https://jito-foundation.gitbook.io/mev/jito-solana/building-the-software

1. Install prerequisites

```sh
# Rust compiler
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup component add rustfmt

# build dependencies (needs sudo)
rustup update
sudo apt-get update
sudo apt-get install libssl-dev libudev-dev pkg-config zlib1g-dev llvm clang cmake make libprotobuf-dev protobuf-compiler
```

2. Select the Testnet/Mainnet CLI version to install
  - See https://discord.com/channels/938287290806042626/1148261936086142996
  - See https://github.com/jito-foundation/jito-solana/releases

  Then set the version as an environment varibale for building

```sh
export TAG=v2.1.13-jito
```

3. Build from Source
  - See https://github.com/jito-foundation/jito-solana/blob/d7f139c74f58d07ba099e7022f322f48b7682db9/start
  - See https://github.com/jito-foundation/jito-solana/blob/d7f139c74f58d07ba099e7022f322f48b7682db9/multinode-demo/setup.sh
  - See https://github.com/jito-foundation/jito-solana/blob/d7f139c74f58d07ba099e7022f322f48b7682db9/multinode-demo/faucet.sh

  <u>Initial setup</u>

```sh
# prepare dirs
mkdir -p ~/.local/share/solana/install/releases
mkdir -p ~/build
cd ~/build

# clone repo
git clone https://github.com/jito-foundation/jito-solana.git --recurse-submodules
cd jito-solana

git status
# On branch master
# Your branch is up to date with 'origin/master'.

git checkout tags/$TAG
# Note: switching to 'tags/v2.1.13-jito'.

git status
# HEAD detached at v2.1.13-jito
# nothing to commit, working tree clean

git submodule update --init --recursive
# Submodule path 'anchor': checked out '4f52f41cbeafb77d85c7b712516dfbeb5b86dd5f'
# Submodule path 'jito-programs': checked out 'd2b9c58189bb69d6f90b1ed513beea8cc9d7c013'

# build
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
# Done after 332 seconds
```

  <u>Update to a new version</u>

```sh
cd jito-solana
git pull
git checkout tags/$TAG
git submodule update --init --recursive
CI_COMMIT=$(git rev-parse HEAD) scripts/cargo-install-all.sh --validator-only ~/.local/share/solana/install/releases/"$TAG"
```

4. Update active release link after install/update

WARNING: 
- This will immediately affect the sol.service if running. That service will crash in a loop until the `sol.service` `systemd` unit is updated to point to the jito startup script containing the jito-specific command line arguments and then restarted with sudo systemctl daemon-reload to pick up the new startup script. You can use `sudo systemd stop sol` to stop the service before updating the link.

```sh
# update active release link
unlink ~/.local/share/solana/install/active_release
ln -sf ~/.local/share/solana/install/releases/"$TAG" ~/.local/share/solana/install/active_release
export PATH=~/.local/share/solana/install/active_release/bin:$PATH

# check installation
which solana
# /home/sol/.local/share/solana/install/active_release/bin/solana

solana --version
# solana-cli 2.1.13 (src:1827a597; feat:1725507508, client:JitoLabs)
```

To add solana cli to your user's PATH, edit `~/.profile` to add the line

```sh
# Add solana to PATH
export PATH=~/.local/share/solana/install/active_release/bin:$PATH
```

## Create Validator Startup Script
- See https://jito-foundation.gitbook.io/mev/jito-solana/command-line-arguments

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
Use the same startup script you would create for the agave-validator and add these extra command line arguments specific for Jito

### Testnet Arguments

Please look at testnet connection information for the values of BLOCK_ENGINE_URL, RELAYER_URL, and SHRED_RECEIVER_ADDR.
- See https://docs.jito.wtf/lowlatencytxnsend/#api

```sh
BLOCK_ENGINE_URL=https://dallas.testnet.block-engine.jito.wtf
RELAYER_URL=http://dallas.testnet.relayer.jito.wtf:8100
SHRED_RECEIVER_ADDR=141.98.218.45:1002
exec agave-validator \
    # base agave-validators parameters...
    --tip-payment-program-pubkey GJHtFqM9agxPmkeKjHny6qiRKrXZALvvFGiKf11QE7hy \
    --tip-distribution-program-pubkey F2Zu7QZiTYUhPd7u9ukRVwxh7B71oA3NMJcHuCHc29P2 \
    --merkle-root-upload-authority GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib \
    --commission-bps 800 \
    --relayer-url ${RELAYER_URL} \
    --block-engine-url ${BLOCK_ENGINE_URL} \
    --shred-receiver-address ${SHRED_RECEIVER_ADDR}
```

### Mainnet Arguments

Please look at mainnet connection information for the values of BLOCK_ENGINE_URL, RELAYER_URL, and SHRED_RECEIVER_ADDR.
- See https://docs.jito.wtf/lowlatencytxnsend/#api

```sh
BLOCK_ENGINE_URL=https://ny.mainnet.block-engine.jito.wtf
RELAYER_URL=http://ny.mainnet.relayer.jito.wtf:8100
SHRED_RECEIVER_ADDR=141.98.216.96:1002
agave-validator \
    # base agave-validators parameters...
    --tip-payment-program-pubkey T1pyyaTNZsKv2WcRAB8oVnk93mLJw2XzjtVYqCsaHqt \
    --tip-distribution-program-pubkey 4R3gSG8BpU4t19KYj8CfnbtRpnT8gtk4dvTHxVRwc2r7 \
    --merkle-root-upload-authority GZctHpWXmsZC1YHACTGGcHhYxjdRqQvTpYkb9LMvxDib \
    --commission-bps 800 \
    --relayer-url ${RELAYER_URL} \
    --block-engine-url ${BLOCK_ENGINE_URL} \
    --shred-receiver-address ${SHRED_RECEIVER_ADDR}
```

3. Start the validator

The script should execute the agave-validator process

```sh
/home/sol/bin/validator-testnet.sh
```

4. After you know your validator es running fine and catching up and already downloaded a snapshot, add the `--no-snapshot-fetch` to the validator script for the next time it starts.

### Update Jito-Specific command line arguments without restarting the validator
- See https://jito-foundation.gitbook.io/mev/jito-solana/command-line-arguments#changing-jito-specific-config

```sh
agave-validator help
# SUBCOMMANDS:
#     authorized-voter                         Adjust the validator authorized voters
#     contact-info                             Display the validator's contact info
#     exit                                     Send an exit request to the validator
#     help                                     Prints this message or the help of the given subcommand(s)
#     init                                     Initialize the ledger directory then exit
#     monitor                                  Monitor the validator
#     plugin                                   Manage and view geyser plugins
#     repair-shred-from-peer                   Request a repair from the specified validator
#     repair-whitelist                         Manage the validator's repair protocol whitelist
#     run                                      Run the validator
#     runtime-plugin                           Manage and view runtime plugins
# --> set-block-engine-config                  Set configuration for connection to a block engine
# --> set-identity                             Set the validator identity
#     set-log-filter                           Adjust the validator log filter
#     set-public-address                       Specify addresses to advertise in gossip
# --> set-relayer-config                       Set configuration for connection to a relayer
# --> set-shred-receiver-address               Changes shred receiver address
# --> set-shred-retransmit-receiver-address    Changes shred retransmit receiver address
#     staked-nodes-overrides                   Overrides stakes of specific node identities.
#     wait-for-restart-window                  Monitor the validator for a good time to restart
```

## Checking Correct Operation (Filtering logs)
- See https://github.com/jito-foundation/stakenet

### Check if we are executing Jito properly ([Retool](https://jito.retool.com/embedded/public/3557dd68-f772-4f4f-8a7b-f479941dba02))
- See https://jito-foundation.gitbook.io/mev/jito-solana/checking-correct-operation

![alt text](/images-webp/validator-setup/jito_check_correct_functioning.webp)

### Check if correctly connecting to relayer and block engine
Look for the following metrics emitted in the validator logfile:
  - `block_engine_stage-stats`: emitted once per second when connected to the block engine.
  - `relayer_stage-stats`: emitted once per second when connected to the relayer.

```sh
tail -n 1000 logs/agave-validator.log | grep block_engine_stage-stats
tail -n 1000 logs/agave-validator.log | grep relayer_stage-stats
```
![alt text](/images-webp/validator-setup/jito_check_connecting_to_relayer_and_block_engine.webp)

### Check if correctly authenticating with relayers and block engine
Look for the following metrics emitted in the validator logfile:
  - `auth_tokens_update_loop-tokens_generated`: emitted infrequently when the validator authenticates with the block engine and relayer.
  - `auth_tokens_update_loop-refresh_access_token`: emitted semi-frequently when the validator refreshes access tokens.
  - `relayer_stage-wait_for_auth` + `block_engine_stage-wait_for_auth`: emitted when waiting to authenticate with the relayer and block engine.
  - `auth_tokens_update_loop-refresh_connect_error`: emitted when the validator can't connect to the relayer and/or relayer. check the url for which one is having issues connecting.
  - `auth_tokens_update_loop-refresh_loop_error`: emitted when there's an error refreshing authentication tokens.
  - `relayer_stage-connect_error` + `block_engine_stage-connect_error`:errors connecting to the relayer or block engine.
  - `relayer_stage-stream_error` + `block_engine_stage-stream_error`: errors streaming from the relayer or block engine.

## Monitor Jito Validators
- See https://jito-foundation.gitbook.io/mev/jito-solana/data-tracking/tracking-jito-solana-validators#current-jito-validators

### Moniror cluster Jito Stake-Weight Over Time

This API gives Jito Network stake-weight on Solana historically as a percent of total stake

```sh
curl -X GET -H "Content-Type: application/json" https://kobe.testnet.jito.network/api/v1/jito_stake_over_time | jq --sort-keys
```
```json
{
  "stake_ratio_over_time": {
    "750": 0.01924339748653111,
    "751": 0.015133299208291569,
    "752": 0.015574514497671301,
    "754": 0.23668474725881497,
    "755": 0.3769719709749734,
    "756": 0.31591671990528297,
    "757": 0.06142453790724538,
    "758": 0.002819805652638113,
    "759": 0.11776922995772128,
    "760": 0.1862094729204557,
    "761": 0.014963033759724013,
    "762": 0.015204421428643259
  }
}
```

### Monitor if your validator is a current Jito validator

<u>Testnet<</u>>

```sh
curl -X GET -H "Content-Type: application/json" https://kobe.testnet.jito.network/api/v1/validators | jq '.validators[] | select(.vote_account == "<vote-account-pubkey>")'
```
```json
{
  "vote_account": "HYtDsj1sa5fFzy6osKuP9WHPPDhwRYBwqCMpxbzTJeSg",
  "mev_commission_bps": 800,
  "mev_rewards": 0,
  "running_jito": true,
  "active_stake": 6009449878620
}
```

<u>Mainnet</u>

```sh
curl -X GET -H "Content-Type: application/json" https://kobe.mainnet.jito.network/api/v1/validators | jq '.validators[] | select(.vote_account == "<vote-account-pubkey>")'
```

## Monitor MEV Rewards
- See https://jito-foundation.gitbook.io/mev/jito-solana/data-tracking/tracking-mev-rewards

### Method 1: Visit [Total MEV Revenue page](https://jito.retool.com/embedded/public/e9932354-a5bb-44ef-bce3-6fbb7b187a89) (Mainnet only)
- See https://jito.retool.com/embedded/public/e9932354-a5bb-44ef-bce3-6fbb7b187a89

![alt text](/images-webp/validator-setup/jito_mev_revenue.webp)

### Method 2: Visit [StakeNet history](https://www.jito.network/stakenet/history/) and filter by validator name, identity or vote account (Mainnet only)

![alt text](/images-webp/validator-setup/jito_stake_net_history.webp)

[Direct link for Hayek Mainnet](https://www.jito.network/validator/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty/)

If there is enough data, you should see detailed info about voting, stake, commission and MEVs. For example, see [this validator](https://www.jito.network/validator/BLADE1qNA1uNjRgER6DtUFf7FU3c1TWLLdpPeEcKatZ2/). 

### Method 3: Using Jito historical MEV rewards API (/api/v1/validators/<vote-account-pubkey>)

You can get historical MEV rewards for a specific validator by vote account. This will return results for a specific validator, sorted by epoch. Note: MEV earned is pre-validator commission.

<u>Testnet</u>

```sh
curl -X GET -H "Content-Type: application/json" https://kobe.testnet.jito.network/api/v1/validators/HYtDsj1sa5fFzy6osKuP9WHPPDhwRYBwqCMpxbzTJeSg | jq
```

<u>Mainnet</u>

```sh
curl -X GET -H "Content-Type: application/json" https://kobe.mainnet.jito.network/api/v1/validators/HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty | jq
```

### Method 4: Specific Epoch Rewards

<u>Testnet</u>

```sh
curl -X POST https://kobe.testnet.jito.network/api/v1/validators  -H "Content-Type: application/json" -d '{"epoch":761}'  | jq '.validators[] | select(.vote_account == "HYtDsj1sa5fFzy6osKuP9WHPPDhwRYBwqCMpxbzTJeSg")'
```
```json
{
  "vote_account": "HYtDsj1sa5fFzy6osKuP9WHPPDhwRYBwqCMpxbzTJeSg",
  "mev_commission_bps": 800,
  "mev_rewards": 0,
  "running_jito": true,
  "active_stake": 6009449878620
}
```

<u>Mainnet</u>

```sh
curl -X POST https://kobe.mainnet.jito.network/api/v1/validators  -H "Content-Type: application/json" -d '{"epoch":761}'  | jq '.validators[] | select(.vote_account == "HAYEKSWg2EY21k38St9X5yM7QMW6SunKDefs5SqYSFty")'
```

Related Docs:
* [Jito Relayer](/ansible-new-michel/roles/jito_relayer/readme.md)