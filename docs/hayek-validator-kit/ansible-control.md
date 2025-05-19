---
description: What is the Ansible Control server inside the Localnet cluster
---

# Ansible Control

With your [Localnet running](solana-localnet.md#running-localnet), you'll have your default node be set as the `ansible-control` container. This node has [Ansible](https://docs.ansible.com/) installed and the goal is to run and automate all sysadmin ops through ansible scripts.&#x20;

Having one of the nodes of the Localnet as the `ansible-control` allows all operators to control remote hosts from an identical environment, rather than having individually setup Ansible configurations on each workstation.&#x20;

## Connect

To connect to your Localnet Ansible Control node, you **HAVE** do it through VSCode or Cursor. When you open the local repo, it will automatically run the cluster, and connect to your Ansible Control node.

Your VSCode terminal should look like this:

<figure><img src="../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

## Validator Keys

Under the Ansible Control node you will find the folder `/hayek-validator-kit/validator-keys` . It contains a script that automatically generates the necessary validator keys when the Localnet cluster is mounted by Docker. These keys are necessary for all validators to function well:

1. **Staked Identity Key**: It will always start with the characters `Z1`
2. **Vote Account Key**: It will always start with the characters `Z2`
3. **Stake Account Key**: It will always start with the characters `Z3`
4. **Authorized Withdrawer Account Key**: It will always start with the characters `Z4` &#x20;
5. **Jito Relayer Block Engine Key**: It will always start with the characters `Z5`&#x20;

&#x20;You can view the full accounts by pasting their respective public keys in the [Localnet Explorers](solana-localnet.md#using-explorers).

## Ansible from Workstation

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

## Packages and Software

The Ansible Control container is provisioned with the following&#x20;

1. Solana CLI
2. Ansible&#x20;
3. Python3
4. These packages: rsyslog, sudo, iproute2, openssh-client, git, curl, nano, openssl, tar, jq, less, tree

## Common CLI Commands

```sh
# Check Solana version
solana --version

# List validators in Localnet
solana -ul validators --keep-unstaked-delinquents

# Verify your validators' ip addresses via Solana gossip 
solana -ul gossip | grep demoneTKvfN3Bx2jhZoAHhNbJAzt2rom61xyqMe5Fcw
```

