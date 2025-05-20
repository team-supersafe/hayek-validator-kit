# Jito Relayer Role

This ROLE is intended to install and run a dedicated co-hosted Jito Relayer for the Solana Validator. This stands in contrast to using a SHARED Jito Relayer, and helps in reducing latency and TPU IP concentration that ultimately yields better rankings for the validator in the cluster. Official Jito docs related to this can be found [HERE](https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer)


# Why build your own Jito Relayer

You should consider running our own Jito Relayer because:
 - It improves decentralization by having a dedicated relayer that only your validator(s) use
 - It minimizes implicit trust in Jito's public shared relayer infra (4 public relayers that receive many connections)
 - It brings your Jito Validator improvements in performance and latency (jito-solana <-> jito-relayer in same metal = near-zero latency)

# Dedicated vs Co-Hosted Setup

There are two options for runing the Jito relayer 
1. Co-Hosted Single Machine (hosted on the same metal as the validator)
    - This is the option recommended by Jito 
    - Does not require external RPC access (it uses the staked validator as RPC)
    - No extra machines to monitor
    - Simpler setup
    - It is a ligher process that should not affect the validator process (needs only a few VCPUs)   

2. Dedicated External Machine (on a separate metal box)
    - Requires monitoring and costs of additinal machine
    - Limits the impact the relayer can have on validator performance
    - Does not require your validator to also run as an RPC
    - Requires reliable RPC access (can specify multiple endpoints)
    - RPC can not be behind tip of network

In this guide we will focus in the recommended approach, which is the Co-Hosted Relayer Setup. If you are interested in exploring the Dedicated Relayer setup, please check the official Jito Docs [HERE](https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer#separate-host-setup).

# Co-Hosted Relayer Setup

Official docs on how to setup a Co-Hosted Relayer are [HERE](https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer#co-hosted-setup)

> **IMPORTANT**:  
A pre-requisitive to setting up the Relayer is to have your [Operator Host correctly setup](/docs/guides/operator_host_setup.md). Please double check you have this OK before proceding.

With your Operator Host setup, you can connect to your Ansible Control node, and run the following playbook:

```sh
ansible-playbook -i playbooks/pb_setup_validator_jito_cohost_relayer.yml -limit local_blue
```

This playbook will print the Jito Block Engine Keypair. This keypair needs to be whitelisted (permissioned) with Jito in order for our relayer to receive re-ordered blocks optimal for MEV. 

To register the Block Engine Keypair with, you must open a ticket in the Jito Discord requesting whitelisting. More details [HERE](https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer#preparation) 

## Verify Relayer Setup

You can verify your replayer stats in the logs (every second) 
```sh 
tail -f solana-validator.log | grep relayer_stage-stats`
```

You can also check perf metrics of the relayer directly on [Jito's metrics dashboard](https://grafana.metrics.jito.wtf:3000).


---
PROGRESS TRACKER 
---

## 2. Generate Block Engine key pair


3. Add validator flags for RPC (more detail next)
4. Add ENV variables for metrics, block engine, grpc bind ip
5. Build and run relayer as separate process

Jito relayer validator flags: TODO

Verify the Jito relayer setup
 


Zantetsu comment about potential issue with Jito relayer creating blocks with small number of transactions. It is recommended to monitor your blocks for a while to make sure they have hundreds of user transactions and not docens or even zero transactions. (possible causes: firewall misconfiguration, websocket misconfiguration)

### Generate Keys (on your localhost)

1. Create dir
```sh
mkdir jito
cd jito
```

2. Generate RSA key pair for the relayer to authenticate validator connections

```sh
openssl genrsa --out jito-relayer-validators-authentication-private-key.pem
openssl rsa --in jito-relayer-validators-authentication-private-key.pem --pubout --out jito-relayer-validators-authentication-public-key.pem
```

3. Generate solana key pair for the relayer to be authenticated by the block engine

```sh
solana-keygen new --no-bip39-passphrase --silent --outfile jito-relayer-block-engine-authentication-private-key.json
```

Then open a ticket (here? https://discord.com/channels/938287290806042626/1045883099935936573) in the Jito Discord to get whitelisted to block engines.

### Build relayer from source (sol user)
- See https://github.com/jito-foundation/jito-relayer/tree/master


2. Select version
- See https://github.com/jito-foundation/jito-relayer/releases


3. Create environment variables for building

```sh
# export TAG=v1.XX.XX-jito # navigate to https://github.com/jito-foundation/jito-solana/releases to see releases
export JITO_RELAYER_TAG=v0.3.1
```

4. Build from source

```sh
mkdir -p /home/sol/build
ca /home/sol/build

git clone https://github.com/jito-foundation/jito-relayer
cd jito-relayer

git status
# Output:
# On branch master
# Your branch is up to date with 'origin/master'.

git checkout tags/$JITO_RELAYER_TAG
# Output:
# Note: switching to 'tags/v0.3.1'.

git status
# Output:
# HEAD detached at v0.3.1
# nothing to commit, working tree clean

# pull submodules to get protobuffers required to connect to Block Engine and validator
git submodule update -i -r # is this the same as git submodule update --init --recursive ?

# build from source
cargo b --release
# ...
# Finished `release` profile [optimized] target(s) in 2m 32s
```

Configure PATH

```sh
mkdir -p /home/sol/.local/share/jito-relayer/install/releases/
mv /home/sol/build/jito-relayer/target/ /home/sol/.local/share/jito-relayer/install/releases/"$JITO_RELAYER_TAG"

# update active release link
unlink ~/.local/share/jito-relayer/install/active_release
ln -sf ~/.local/share/jito-relayer/install/releases/"$JITO_RELAYER_TAG" ~/.local/share/jito-relayer/install/active_release
export PATH=~/.local/share/jito-relayer/install/active_release/release:$PATH

# check installation
which jito-transaction-relayer
# /home/sol/.local/share/jito-relayer/install/active_release/release/jito-transaction-relayer

jito-transaction-relayer --version
# jito-transaction-relayer 0.3.1
```

### Running the relayer (Co-Hosted Setup)
- See https://jito-foundation.gitbook.io/mev/jito-relayer/running-a-relayer#co-hosted-setup

1. Add these command line flags to your agave-validator script

```sh
# Extra Agave Validator CLI Arguments for Co-Hosted Relayer
    --relayer-url http://127.0.0.1:11226 \
    --private-rpc \
    --full-rpc-api \ # do we need full api here ???
    --rpc-port 8899 \
    --account-index program-id \
    --account-index-include-key AddressLookupTab1e1111111111111111111111111 \
```

2. Copy over the Jito generated keys from your localhost to the remote validator (hayek-testnet)

```sh
# make sure folder exists

ssh sol@<REMOTE_VALIDATOR_HOST> "mkdir -p ~/keys/jito"

scp "$LOCAL_KEYS_DIR/jito-relayer-block-engine-authentication-private-key.json" sol@<REMOTE_VALIDATOR_HOST>:/home/sol/spsf-testnet/jito/
# jito-relayer-block-engine-authentication-private-key.json                                               100%  219    93.0KB/s   00:00 

scp ./jito/jito-relayer-block-engine-authentication-*-key.json sol@<REMOTE_VALIDATOR_HOST>:/home/sol/spsf-testnet/jito/
scp ./jito/jito-relayer-validators-authentication-*-key.pem sol@<REMOTE_VALIDATOR_HOST>:/home/sol/spsf-testnet/jito/
# jito-relayer-validators-authentication-private-key.pem                                                  100% 1704   833.7KB/s   00:00    
# jito-relayer-validators-authentication-public-key.pem                                                   100%  451   507.4KB/s   00:00

```

2. Configure relayer as a `systemd` service

Template for Systemd unit for Co-Hosted Relayer

```sh
# Example Systemd File for Co-Hosted Relayer
[Unit]
Description=Solana transaction relayer
Requires=network-online.target
After=network-online.target

# User is required to install a keypair here that's used to auth against the block engine
ConditionPathExists=${PATH_TO_KEYS}/id.json
ConditionPathExists=${PATH_TO_KEYS}/private.pem
ConditionPathExists=${PATH_TO_KEYS}/public.pem

[Service]
Type=exec
User=${USER}
Restart=on-failure
Environment=RUST_LOG=info
Environment=SOLANA_METRICS_CONFIG="host=http://metrics.jito.wtf:8086,db=relayer,u=relayer-operators,p=jito-relayer-write"
Environment=BLOCK_ENGINE_URL=${BLOCK_ENGINE_URL}
Environment=GRPC_BIND_IP=127.0.0.1

ExecStart=${RELAYER_PATH}/jito-transaction-relayer \
          --keypair-path=/etc/relayer/keys/id.json \
          --signing-key-pem-path=/etc/relayer/keys/private.pem \
          --verifying-key-pem-path=/etc/relayer/keys/public.pem

[Install]
WantedBy=multi-user.target
```
Replace these values:
 - `PATH_TO_KEYS`: the ones you generated above
 - `USER`: the user that will be used to run the service
 - `BLOCK_ENGINE_URL`: the same engine url used in the jito-solana startup script
 - `RELAYER_PATH`: path to your relayer executable and make sure that it has executable permissions
 - `RUST_LOG`: to emit info level datapoints to the metrics server

Using a user with sudo access, create/edit the file `/etc/systemd/system/sol.service` 
```sh
sudo nano /etc/systemd/system/relayer.service
```

Testnet Systemd unit for Co-Hosted Relayer
```sh
# Example Systemd File for Co-Hosted Relayer
[Unit]
Description=Jito-Solana transaction relayer
Requires=network-online.target
After=network-online.target

# User is required to install a keypair here that's used to auth against the block engine
ConditionPathExists=/home/sol/spsf-testnet/jito/jito-relayer-block-engine-authentication-private-key.json
ConditionPathExists=/home/sol/spsf-testnet/jito/jito-relayer-validators-authentication-private-key.pem
ConditionPathExists=/home/sol/spsf-testnet/jito/jito-relayer-validators-authentication-public-key.pem

[Service]
Type=exec
User=sol
Restart=on-failure
Environment=RUST_LOG=info
Environment=SOLANA_METRICS_CONFIG="host=http://metrics.jito.wtf:8086,db=relayer,u=relayer-operators,p=jito-relayer-write"
Environment=BLOCK_ENGINE_URL=https://dallas.testnet.block-engine.jito.wtf
Environment=GRPC_BIND_IP=127.0.0.1

ExecStart=/home/sol/.local/share/jito-relayer/install/active_release/release/jito-transaction-relayer \
          --keypair-path=/home/sol/spsf-testnet/jito/jito-relayer-block-engine-authentication-private-key.json \
          --signing-key-pem-path=/home/sol/spsf-testnet/jito/jito-relayer-validators-authentication-private-key.pem \
          --verifying-key-pem-path=/home/sol/spsf-testnet/jito/jito-relayer-validators-authentication-public-key.pem

[Install]
WantedBy=multi-user.target
```

- TODO Mainnet Systemd unit for Co-Hosted Relayer

```sh
```

Then reload the service
```sh
sudo systemctl daemon-reload
```

WIP...

## Jito Relayer Role Variables

| Variable                        | Default Value                                                      | Description                                                                                   |
|----------------------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `jito_relayer_install_dir`      | `/home/sol/.local/share/jito-relayer/install/active_release/release` | Path to the directory containing the built Jito relayer binary.                               |
| `jito_relayer_keys_dir`          | `/home/sol/spsf-testnet/jito`                                     | Directory where relayer key files (private/public keys, block engine keypair) are stored.     |
| `jito_relayer_user`              | `sol`                                                             | The system user that runs the relayer and owns the files.                                     |
| `jito_relayer_block_engine_url`  | `https://dallas.testnet.block-engine.jito.wtf`                    | The block engine URL to connect to (override for mainnet, etc.).                              |
| `jito_relayer_metrics_config`    | `host=http://metrics.jito.wtf:8086,db=relayer,u=relayer-operators,p=jito-relayer-write` | Metrics server configuration string.                                                          |

**Note:** You should override these variables in your playbook or inventory as needed for your environment (e.g., for mainnet, different user, or custom paths).