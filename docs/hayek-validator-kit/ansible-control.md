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

