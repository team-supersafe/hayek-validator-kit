# Solana Localnet

Solana has three public clusters: `Mainnet`, `Testnet` and `Devnet`. All of these require coordination with other parties in one way or another, and it becomes hard for devs to reset state when developing locally.

The Hayek Validator Toolkit includes a fourth cluster named `Localnet`, which runs 100% inside a Docker container, and spins up a fully functioning Solana network with multiple coordinating validators in seconds.

## Benefits

**Exploration**: The main benefit of the Solana Localnet is that it promotes exploration without fear. It is a disposable environment that is easy to setup, take down, change, and break as much as you want.

**Speed**: Launching the Solana Localnet in your workstation takes seconds. Coordinating between nodes is instant.

**State**: Resetting state of a validator node, spining a new validator that can join Localnet, or turning off validators is near instant. Even better, you can completely delete the docker localnet cluster, and spin it again if you feel you corrupted the state doing something.

**Automation**: One of the nodes of Localnet is an [Ansible Control node](ansible-control.md), which will let you run ansible scripts against your Localnet nodes as well as Mainnet and Testnet.

## Workstation Setup

Before running the Hayek Validator Kit Solana Localnet, you must [setup your workstation](workstation-setup.md) for success.

All the configurations related to the Hayek Validator Kit are in this [GitHub repo](github-repo.md), which you will have to clone locally if you have not done so already:

```bash
git clone https://github.com/team-supersafe/hayek-validator-kit.git
```

You should [get familiar with the contents of the repo](github-repo.md#navigating-the-repo). The Localnet cluster is defined in the `Dockerfile` and `docker-compose.yml` files under the `solana-localnet` folder.

## The Localnet Cluster

### Pre-Provisioned Demo Key Set

We have pre-provisioned a sets of keys called `demo1`  only for demonstration and debugging purposes.&#x20;

| Name               | Address                                       | Explorer links                                                                                                                                                                                                                                                                                |
| ------------------ | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| validator identity | `demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw` | [solana explorer](https://explorer.solana.com/address/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899), [solscan](https://solscan.io/account/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http://localhost:8899) |
| vote account       | `demo52s9s1foFXgnbVa8vYQM8GS9XRsJ3aMpus1rNnb` | [solana explorer](https://explorer.solana.com/address/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899), [solscan](https://solscan.io/account/demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw?cluster=custom\&customUrl=http://localhost:8899) |
| user stake account | `demoMwLKQwfPZpjrbGG7Ed6vbXizxFDCp5srVd1Hqky` | [solana explorer](https://explorer.solana.com/address/demoMwLKQwfPZpjrbGG7Ed6vbXizxFDCp5srVd1Hqky?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899), [solscan](https://solscan.io/account/demoMwLKQwfPZpjrbGG7Ed6vbXizxFDCp5srVd1Hqky?cluster=custom\&customUrl=http://localhost:8899) |

The `demo1` identity key will be running with 200k SOL staked in Localnet every time you start the cluster. These 200k SOL represents roughly \~16% of all cluster stake.

### Host Inventory

The Localnet cluster consist of the following containers:

<table><thead><tr><th width="260.39453125">Container Node</th><th>Key Features</th></tr></thead><tbody><tr><td><code>gossip-entrypoint</code><br>- SSH port binding: <code>localhost:9022</code></td><td><p>The cluster's Gossip protocol entry point node. Any validator can use this to join the network and synchronize with other validators.</p><ul><li>It provides Genesis block for Solana Localnet</li><li>Kick-starts POH</li><li>Epoch = 750 slots (~5 min)</li><li>Mostly for cluster boilerplate and not meant to be modified</li></ul></td></tr><tr><td><p><code>host-alpha</code></p><p>- SSH port binding: <code>localhost:9122</code></p></td><td><p>Running the <code>demo1</code> validator key set with:</p><ul><li>200K delegated SOL (~16% of all cluster stake)</li></ul></td></tr><tr><td><code>host-bravo</code><br>- SSH port binding: <code>localhost:9222</code></td><td>A validator-ready container without a validator key set. It does not have any validator running, but the tooling is already installed.</td></tr><tr><td><code>host-charlie</code><br>- SSH port binding: <code>localhost:9322</code></td><td>A naked Ubuntu 24.04. This guy is not ready for anything. This is good to test bare-bone provisioning scripts.</td></tr><tr><td><p><code>ansible-control</code><br>- Not SSH bound</p><p>- See <a href="ansible-control.md#connecting-to-ansible-control">how to connect</a></p></td><td><p>Your official sysadmin automation environment:</p><ul><li>Solana CLI and Ansible installed</li><li>Access Solana Mainnet, Testnet and Localnet</li></ul><pre><code># For Mainnet Connectivity
solana -um ***
#For Testnet Connectivity
solana -ut ***
For Localnet Connectivity
solana -ul ***
or also "solana -url localhost (-ul)"
</code></pre><ul><li>Connect to any Localnet container <a href="ansible-control.md#connecting-to-localnet-nodes">via SSH</a>.</li></ul></td></tr></tbody></table>

After the cluster is provisioned, the staked SOL delegated to the `demo1` key set will be active at the beginning of Epoch 1 (after \~5 minutes). Then the `demo1` validator will start voting and move from delinquent to not-delinquent at the beginning of Epoch 2.

### Using Explorers

You can use the Solana Explorer and Solscan apps to explore any accounts in your localnet cluster using these addresses:

* [https://explorer.solana.com/?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899](https://explorer.solana.com/?cluster=custom\&customUrl=http%3A%2F%2Flocalhost%3A8899)
* [https://solscan.io/?cluster=custom\&customUrl=http://localhost:8899](https://solscan.io/?cluster=custom\&customUrl=http://localhost:8899)

### Running Localnet on Unix-based OS

We use Docker to run Localnet:

1. **IDE Option (recommended)**\
   Open the repo in VSCode or another popular IDE and select "Reopen in Container" or similar option. This will use the Dev Containers extension to automatically run the services containers defined in `docker-compose.yml` and trigger the build process of the images in the `Dockerfile`  if needed.
2.  **Terminal Option**\
    Another option, for those VSCode haters, is the run Localnet directly from the terminal by running:

    ```bash
    cd solana-localnet
    ./start-localnet-from-outside-ide.sh
    ```

Congratulations! You are now running Solana Localnet, connected to your [Ansible Control](ansible-control.md) and ready to make a mess of your Localnet playground.

### Running Localnet on Windows

There are some things that are unique to running Localnet on Windows (as opposed to MacOS or Linux). &#x20;

1. Install VS Code for Windows: [https://code.visualstudio.com/download](https://code.visualstudio.com/download)
2.  Install WSL: [https://learn.microsoft.com/es-es/windows/wsl/install](https://learn.microsoft.com/es-es/windows/wsl/install)&#x20;

    ```powershell
    wsl -install
    ```
3. Open the “wsl distro" from the start menu (Ubuntu by default) and create your Linux username and password. Note that these credentials are independent of your Windows account.
4. Install ANSIBLE in the WSL environment:
   1.  Run the following command to update the system repository information:&#x20;

       ```bash
       sudo apt update && sudo apt upgrade -y
       ```
   2.  Install the prerequisite packages that allow you to add the official Ansible PPA:&#x20;

       ```bash
       sudo apt install software-properties-common
       ```
   3.  Add the PPA with the following command and install the package:&#x20;

       ```bash
       sudo apt-add-repository ppa:ansible/ansible
       sudo apt update
       sudo apt install ansible -y
       ```
5.  Install the package dos2unix:&#x20;

    ```bash
    sudo apt install dos2unix
    ```

{% hint style="warning" %}
Dos2unix is a command-line utility used to convert text files from DOS/MAC format, which uses carriage return and line feed (CRLF) for line endings, to Unix format, which uses only line feed (LF). This conversion helps ensure compatibility when transferring files between different operating systems.
{% endhint %}

6. Go to the `solana-localnet` folder, the path should look like this:

```
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/hayek-validator-kit/solana-localnet
```

Run the following command:

```bash
sudo dos2unix *.sh
```

7. In VS Code, create a **.env** file for the environment variables. Paste the following variables, taking care to replace YOUR\_WINDOWS\_USERNAME placeholder with the proper one:

```
ANSIBLE_REMOTE_USER=YOUR_WINDOWS_USERNAME
SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```

{% hint style="warning" %}
Remember to create and save your workspace in Visual Studio Code.
{% endhint %}

8. Install the following programs on the Windows host:
   1. Docker desktop for windows: [https://docs.docker.com/desktop/setup/install/windows-install/](https://docs.docker.com/desktop/setup/install/windows-install/)
   2. Python: [https://www.python.org/downloads/windows/](https://www.python.org/downloads/windows/)
9. In VS Code use the option “reopen from container”.&#x20;
10. Check that the containers are running on Docker Desktop:

<figure><img src="../.gitbook/assets/image (5).png" alt=""><figcaption></figcaption></figure>

### Resetting Localnet

At times, and as you corrupt the state of your docker containers running in Localnet, you may need to reset your docker Localnet cluster to start fresh. You can accomplish this by selecting the options of "Reopen in Container" or "Rebuild Container" within VSCode.

You can also stop the cluster from docker with:

```bash
cd solana-localnet
docker compose down
```

## SSH into nodes

### From Workstation

<pre class="language-sh"><code class="lang-sh">ssh -p 9122 sol@localhost # ssh into alpha host
<strong>ssh -p 9222 sol@localhost # ssh into bravo host
</strong>ssh -p 9322 sol@localhost # ssh into charlie host
</code></pre>

Ports are mapped from your localhost to each container:

* `localhost:9022` → `gossip-entrypoint:22`
* `localhost:9122` → `host-alpha:22`
* `localhost:9222` → `host-bravo:22`
* `localhost:9322` → `host-charlie:22`

### From Ansible Control

```sh
ssh sol@host-alpha # ssh into host-alpha node
ssh sol@host-bravo # ssh into host-bravo node
ssh sol@host-charlie # ssh into host-charlie node
```

## Using the Solana CLI in localnet

We will use the `solana gossip` and `solana validators` command to illustrate how to correctly configure the RPC url depending on from where we are running the commands.

### Directly from our workstation

```bash
solana --url localhost gossip # or just solana -ul gossip
solana --url localhost validators # or just solana -ul validators
```

### From ansible-control

<pre class="language-bash"><code class="lang-bash"><strong>solana --url localhost gossip # or just solana -ul gossip
</strong>solana --url localhost validators # or just solana -ul validators
</code></pre>

### From a validator node

After the first login into one of the validator hosts (`host-alpha` and `host-bravo`), we set the `RPC_URL` environment variable pointing to the `gossip-entrypoint` host, so we can use that variable when using the Solana CLI, like so:

```bash
# This varibale is already set when provisioning the cluster
# RPC_URL=http://gossip-entrypoint:8899

solana --url $RPC_URL gossip # or just solana -u $RPC_URL gossip
solana --url $RPC_URL validators # or just solana -u $RPC_URL validators
```

Other common validator CLI commands can be found [HERE](../validator-operations/deploying-a-validator-client/agave.md#common-commands).

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
agave-validator \
    --identity /home/sol/keys/demo1/identity.json \
    --vote-account demo52s9s1foFXgnbVa8vYQM8GS9XRsJ3aMpus1rNnb \
    --authorized-voter /home/sol/keys/demo1/primary-target-identity.json \
    --log agave-validator.log \
    --ledger /mnt/ledger \
    --accounts /mnt/accounts \
    --snapshots /mnt/snapshots \
    --allow-private-addr \
    --rpc-port 9999 \
    --no-os-network-limits-test \
    --known-validator 3jHsYXrWP7GrmBhzkGHp84EEwAvLtKnD6SZC9r6LM3Ji \
    --only-known-rpc

```

## Troubleshooting <a href="#troubleshuting" id="troubleshuting"></a>

If your validator doesn't show up as a running process or the process is running but it never catches up of falls behind, make sure to check the logs before anything else:

```sh
tail ~/logs/agave-validator.log
```

## References

Reference credits for the Dockerfile for ubuntu-ansible:

* [https://github.com/geerlingguy/docker-ubuntu2404-ansible/blob/master/Dockerfile](https://github.com/geerlingguy/docker-ubuntu2404-ansible/blob/master/Dockerfile)
