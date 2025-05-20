# Solana Localnet

Solana has three public clusters: `Mainnet`, `Testnet` and `Devnet`. All of these require coordination with other parties in one way or another, and it becomes hard for devs to reset state when developing locally.&#x20;

The Hayek Validator Toolkit includes a fourth cluster named `Localnet`, which runs 100% inside a Docker container, and spins up a fully functioning Solana network with multiple coordinating validators in seconds.&#x20;

## Benefits

**Exploration**: The main benefit of the Solana Localnet is that it promotes exploration without fear. It is a disposable environment that is easy to setup, take down, change, and break as much as you want.

**Speed**: Launching the Solana Localnet in your workstation takes seconds. Coordinating between nodes is instant.&#x20;

**State**: Resetting state of a validator node, spining a new validator that can join Localnet, or turning off validators is near instant. Even better, you can completely delete the docker localnet cluster, and spin it again if you feel you corrupted the state doing something.

**Automation**: One of the nodes of Localnet is an [Ansible Control node](ansible-control.md), which will let you run ansible scripts against your Localnet nodes as well as Mainnet and Testnet.

## Workstation Setup

Before running the Hayek Validator Kit Solana Localnet, you must [setup your workstation](workstation-setup.md) for success.&#x20;

All the configurations related to the Hayek Validator Kit are in this [GitHub repo](github-repo.md), which you will have to clone locally if you have not done so already:&#x20;

```bash
git clone https://github.com/team-supersafe/hayek-sol-validator.git
```

You should [get familiar with the contents of the repo](github-repo.md#navigating-the-repo). The Localnet cluster is defined in the `Dockerfile` under the `solana-localnet` folder.

## The Localnet Cluster

### Host Inventory

The Localnet cluster consist of the following containers:

<table><thead><tr><th width="260.39453125">Container Node</th><th>Key Features</th></tr></thead><tbody><tr><td><code>entrypoint</code><br>- Maps to localhost:9022</td><td><p>The Localnet cluster Gossip entry point node. Other validator nodes use this to join the network and synchronize with other validators.</p><ul><li>It provides Genesis block for Solana Localnet</li><li>Kick-starts POH</li><li>Epoch = 750 slots (~5 min) </li><li>Mostly for cluster boilerplate and not meant to be modified </li></ul></td></tr><tr><td><code>host-alpha</code><br>- Maps to localhost:9122</td><td><p>Running a validator named <code>Canopy</code> with:</p><ul><li>200K delegated SOL (~16% of all cluster stake)</li><li>See how to view the <code>Canopy</code> validator keys in the <a href="ansible-control.md#validator-keys">Validator Keys section</a>.</li></ul></td></tr><tr><td><code>host-bravo</code><br>- Maps to localhost:9222<br></td><td>A validator-ready container without a validator key set. It does not have any validator running, but the tooling is already installed.</td></tr><tr><td><code>host-charlie</code><br>- Maps to localhost:9322</td><td>A naked Ubuntu 24.04. This guy is not ready for anything. This is good to test bare-bone provisioning scripts.</td></tr><tr><td><p><code>ansible-control</code><br>- Not mapped</p><p>- See <a href="ansible-control.md#connecting-to-ansible-control">how to connect</a></p></td><td><p>Your official sysadmin automation environment:</p><ul><li>Solana CLI and Ansible installed</li><li>Access Solana Mainnet, Testnet and Localnet</li></ul><pre><code># For Mainnet Connectivity
solana -um ***

#For Testnet Connectivity
solana -ut ***

# For Localnet Connectivity
solana -ul ***
# or also "solana -url localhost (-ul)"
</code></pre><ul><li>Connect to any Localnet container <a href="ansible-control.md#connecting-to-localnet-nodes">via SSH</a>.</li></ul></td></tr></tbody></table>

After the cluster is provisioned, the staked SOL delegated to the `Canopy` node will be active at the beginning of Epoch 1 (after \~5 minutes). Then the `Canopy` validator will start voting and move from delinquent to not-delinquent at the beginning of Epoch 2.&#x20;

### Using Explorers

You can use the Solana Explorer and Solscan apps to explore any accounts in your localnet cluster using these addresses:

* [https://explorer.solana.com/?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899](https://explorer.solana.com/address/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899)
* [https://solscan.io/?cluster=custom\&customUrl=http://localhost:8899](https://solscan.io/account/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http://localhost:8899)

### Running Localnet

To run Localnet you must run it in Docker

1. **IDE Option (recommended)** \
   Open the repo in VSCode. This will automatically run the `docker-compose.yml` with `docker compose up` and trigger the build process of the images in the `Dockerfile`
2.  **Docker Option**\
    Another option, for those VSCode haters, is the run Localnet directly from Docker by running:&#x20;

    ```bash
    cd solana-localnet
    docker compose up --detach
    ```

Congratulations! You are now running Solana Localnet, connected to your [Ansible Control](ansible-control.md) and ready to make a mess of your Localnet playground.

### Resetting Localnet

At times, and as you corrupt the state of your docker containers running in Localnet, you may need to reset your docker Localnet cluster to start fresh. You can accomplish this by selecting the options of "Reopen in Container" or "Rebuild Container" within VSCode.

<figure><img src="../.gitbook/assets/image.png" alt=""><figcaption></figcaption></figure>

You can also stop the cluster from docker with&#x20;

```bash
cd solana-local-cluster
docker compose down
```

## SSH into nodes

### From Workstation

```sh
ssh -p 9122 sol@host-alpha # ssh into alpha host
ssh -p 9222 sol@host-bravo # ssh into bravo host
```

Ports are mapped from your localhost to each container:

* for `host-alpha`: localhost:9122 maps to container 22
* for `host-bravo`: localhost:9222 maps to container 22

### From Ansible Control

```sh
ssh sol@primary # ssh into primary node
ssh sol@secondary # ssh into secondary node
```

## Validator CLI Commands

After the first login to a validator that was just setup, you'll need to have it join Localnet by setting its entrypoint, like so:&#x20;

```bash
# After login, set the RPC url to point to the entrypoint node
RPC_URL=http://entrypoint:8899
```

Other common validator CLI commands can be found [HERE](../validator-operations/validator-commands.md).

## Cluster Example

### Entrypoint Node

An entrypoint container can use this command to run:

```sh
solana-test-validator \
    --slots-per-epoch 750 \
    --limit-ledger-size 500000000 \
    --dynamic-port-range 8000-8020 \
    --rpc-port 8899 \
    --bind-address 0.0.0.0 \
    --gossip-host $(hostname -i | awk '{print $1}') \
    --gossip-port 8001 \
    --reset
```

... and it will output the following:

```sh
2025-04-01 10:04:00 Notice! No wallet available. `solana airdrop` localnet SOL after creating one
2025-04-01 10:04:00 
2025-04-01 10:04:00 Ledger location: test-ledger
2025-04-01 10:04:00 Log: test-ledger/validator.log
2025-04-01 10:04:00 Initializing...
2025-04-01 10:04:05 Waiting for fees to stabilize 1...
2025-04-01 10:04:05 Connecting...
2025-04-01 10:04:05 Identity: 3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji
2025-04-01 10:04:05 Genesis Hash: 2d6eCexwpnhp66pcKidbTDaczqnnG6zBiHRK196MoFvn
2025-04-01 10:04:05 Version: 2.1.16
2025-04-01 10:04:05 Shred Version: 64483
2025-04-01 10:04:05 Gossip Address: 172.21.0.3:8001
2025-04-01 10:04:05 TPU Address: 172.21.0.3:8003
2025-04-01 10:04:05 JSON RPC URL: http://172.21.0.3:8899
2025-04-01 10:04:05 WebSocket PubSub URL: ws://172.21.0.3:8900

# ENTRYPOINT_IDENTITY_PUBKEY=3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji
```

If `--gossip-host <IP_ADDRESS>` is not provided here, any `agave-validator` client trying to connect through gossip will try hard for a while...

{% code overflow="wrap" %}
```
Searching for an RPC service with shred version 36796 (Retrying: Wait for known rpc peers)...
[2025-03-29T18:02:26.010433513Z INFO  agave_validator::bootstrap] Total 0 RPC nodes found. 0 known, 0 blacklisted
```
{% endcode %}

... and eventually die with this message:

{% code overflow="wrap" %}
```
[2025-03-29T18:05:00.275887418Z ERROR agave_validator::bootstrap] Failed to get RPC nodes: Unable to find any RPC peers. Consider checking system clock, removing `--no-port-check`, or adjusting `--known-validator ...` arguments as applicable
```
{% endcode %}

### Validator Nodes <a href="#validator-nodes" id="validator-nodes"></a>

```sh
ENTRYPOINT_IDENTITY_PUBKEY=3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji

# primary validator node
agave-validator --entrypoint entrypoint:8001 \
    --identity ~/keys-localtest/identity.json \
    --vote-account FadfWQhHGwdQQWbvscyiNLedbBr6q9DDWqfU2bWyhmwx \
    --authorized-voter ~/keys-localtest/staked-identity.json \
    --log agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --allow-private-addr --rpc-port 9999 \
    --no-os-network-limits-test \
    --known-validator 3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji \
    --only-known-rpc

# secondary validator node
agave-validator --entrypoint entrypoint:8001 \
    --identity ~/keys-localtest/identity.json \
    --vote-account FadfWQhHGwdQQWbvscyiNLedbBr6q9DDWqfU2bWyhmwx \
    --authorized-voter ~/keys-localtest/staked-identity.json \
    --log agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --allow-private-addr --rpc-port 9999 \
    --no-os-network-limits-test \
    --known-validator 3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji \
    --only-known-rpc
```

## Troubleshooting <a href="#troubleshuting" id="troubleshuting"></a>

If your validator doesn't show up as a running process or the process is running but it never catches up of falls behind, make sure to check the logs before anything else:&#x20;

```sh
tail ~/logs/agave-validator.log
```

## References

Reference credits for the Dockerfile for ubuntu-ansible:&#x20;

* [https://github.com/geerlingguy/docker-ubuntu2404-ansible/blob/master/Dockerfile](https://github.com/geerlingguy/docker-ubuntu2404-ansible/blob/master/Dockerfile)
