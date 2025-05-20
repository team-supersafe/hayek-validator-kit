---
description: What is the Ansible Control server inside the Localnet cluster
---

# Ansible Control

With your [Localnet running](solana-localnet.md#running-localnet), you'll have your default node be set as the `ansible-control` container. This node has [Ansible](https://docs.ansible.com/) installed and the goal is to run and automate all sysadmin ops through ansible scripts.&#x20;

Having one of the nodes of the Localnet as the `ansible-control` allows all operators to control remote hosts from an identical environment, rather than having individually setup Ansible configurations on each workstation.&#x20;

## Pre-Provisioned Assets

### Canopy Validator Key Set

We have pre-provisioned a sets of keys for the `Canopy` validator that will be running with 200k SOL staked in Localnet every time you start the cluster. These 200k SOL represents roughly \~16% of all cluster stake... which is a lot... and that's why we named it `Canopy` .

### Creating Validator Key Sets

Under the Ansible Control node you will find the script:

&#x20;`/hayek-validator-kit/validator-keys/_gen-validator-keys.sh`&#x20;

This script generates a new set of validator keys. These will be needed when provisioning a new validator on any of the containers in the Localnet cluster. A set of keys contains the following:

1. **Staked Identity Key**: It will always start with the characters `Z1`
2. **Vote Account Key**: It will always start with the characters `Z2`
3. **Stake Account Key**: It will always start with the characters `Z3`
4. **Authorized Withdrawer Account Key**: It will always start with the characters `Z4` &#x20;
5. **Jito Relayer Block Engine Key**: It will always start with the characters `Z5`&#x20;
6. **Jito Relayer Comms Key**: RSA keys in the `jito-relayer-comms-private.pem` and `jito-relayer-comms-public.pem` files.

{% hint style="info" %}
There is never the need to run this script manually if you provision your validators using the Hayek Validator Kit Ansible playbooks provided, since they do this automatically for us. However, for development purposes it may be useful to understand this part a little further, ergo we take the time to explain more.
{% endhint %}

To generate a new set of keys, you should give them a name (aka: the validator name) and run the following commands from your Ansible Control:

```bash
# Set the keys directory and name your validator
KEYS_DIRECTORY="/hayek-validator-kit/validator-keys"
VALIDATOR_NAME="Sprout"

# Make a new directory for your key set
mkdir -p "$KEYS_DIRECTORY/$VALIDATOR_NAME"

# Move to the new key set directory
cd "$KEYS_DIRECTORY/$VALIDATOR_NAME"

# Run the script on the directory
$KEYS_DIRECTORY/_gen-validator-keys.sh
```

You can view the public keys of any of these respective private keys like this:

```bash
solana-keygen pubkey staked-identity.json
```

For convenience, we have also generated the public keys as a separate empty file for each of the keys. Each file-pair should look like this:&#x20;

```
staked-identity-Z1RtExJVeFskxLD1D6RCPHH9NBpLHvcqKW8iXZfkMEK
staked-identity.json
```

You can view the full accounts by pasting their respective public keys in the [Localnet Explorers](solana-localnet.md#using-explorers).

### Packages and Software

The Ansible Control container is provisioned with the following&#x20;

1. Solana CLI
2. Ansible&#x20;
3. Python3
4. These packages: rsyslog, sudo, iproute2, openssh-client, git, curl, nano, openssl, tar, jq, less, tree

## Naming Validators

As you name new validators in Localnet or create new validator key sets, it will help you to think about their name relative to their total stake they will have. Our approach is to name the validators as follows:

* **Canopy**, Whale, Benjamin = large stake
* **Sprout**, Dolphin, Dollar = medium stake
* **Seed**, Shrimp, Penny = small stake

## Connecting to Ansible Control

To run playbooks and connect to the different validator nodes inside your Localnet, you must first connect to the Ansible Control node. Think of it as your Command Center for everything Solana from this point on.

### From Workstation VS Code (Recommended)

To connect to your Localnet Ansible Control node, you **HAVE** do it through VSCode or Cursor. When you open the local repo, it will automatically run the cluster, and connect to your Ansible Control node.

Your VSCode terminal should look like this:

<figure><img src="../.gitbook/assets/terminal.webp" alt=""><figcaption></figcaption></figure>

### From Workstation Terminal

The Ansible Control node is a special docker container and you cannot directly ssh into it from your workstation terminal. You can connect to it like this:

```bash
# List the running containers from your docker engine
docker ps

# Connect to the container named 'ansible-control' and load 'bash'
docker exec -it ansible-control bash

# You may end up here: [ansible-control:/opt/code/tools
# If you do, just cd into the hayek-validator-kit folder
cd /hayek-validator-kit
```

## Connecting to Localnet Nodes

You can connect from your Ansible Control to any of your [Localnet Containers](solana-localnet.md#host-inventory) using SSH as follows:

```bash
# ssh <host-user>@<localnet-container>
ssh sol@alpha
```

## Ignoring Ansible Control

{% hint style="warning" %}
This option is not the recommended one. If you are stubborn and want to go this route, the rest of these docs may not make sense.
{% endhint %}

If you REALLY REALLY want to run the Ansible scripts from your workstation directly, instead of the Ansible Control node in Localnet, you'll need to install Ansible like this:

```sh
# install Ansible
# See https://ansible.readthedocs.io/projects/lint/installing/
pip3 install ansible
ansible --version

# install ansible-lint
pip3 install ansible-lint
ansible-lint --version
```

Another issue when running your containers NOT within the [Ansible Control within VS Code](ansible-control.md#from-workstation-vs-code-recommended), is that you will have to take care of managing the resources used by your Docker environment. When using Ansible Control within VS Code, the IDE automatically shuts down and reloads the containers when you open and close the repo folder.

```bash
docker compose down
```

## Common CLI Commands

```sh
# Check Solana version
solana --version

# List validators in Localnet
solana -ul validators --keep-unstaked-delinquents

# Verify your validators' ip addresses via Solana gossip 
solana -ul gossip | grep demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw
```

