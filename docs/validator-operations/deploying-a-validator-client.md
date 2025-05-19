---
description: \
---

# Deploying a validator client

The process to deploy a new validator using the Agave client is similar to that of upgrading an existing client to a new version of Agave. The process goes like this:

* For Mainnet and Testnet deployments, Agave is always BUILT FROM SOURCE directly on the host machine.&#x20;
* For Localnet, which is focused on development and operator workloads, we want to avoid having to BUILD FROM SOURCE every time we spin up a new docker container, since the build process itself is very resource intensive and slows down the development REPL.

Make sure you understand [Localnet and its requirements](../hayek-validator-kit/solana-localnet.md) before deploying to it.

## On Localnet

For [Localnet](../hayek-validator-kit/solana-localnet.md), which is focused on development and operator workloads, we want to **avoid** having to BUILD FROM SOURCE every time we spin up a new docker container, since the build process itself is very resource intensive and slows down the development REPL. For this reason, all Localnet deployments are done from pre-compiled binaries.&#x20;

Anza publishes new releases of Agave at [https://github.com/anza-xyz/agave/releases](https://github.com/anza-xyz/agave/releases). However, they **don't** publish pre-built binaries for Apple Silicon running virtualized hosts, which is not an uncommon setup for developer workstations.

To accomodate these developers and operators, we pre-compile binaries for Apple Silicon and store them in an accessible place so Docker and Ansible can use them in their Localnet.

1.  On a workstation running Apple Silicon, connect to the Ansible Control on your Localnet and run&#x20;

    ```yaml
    ansible-playbook -i hosts.yml playbooks/pb_install_solana_cli.yml --limit secondary
    ```
2. Download source code from [https://github.com/anza-xyz/agave/releases](https://github.com/anza-xyz/agave/releases)
3.  Some devs use localnet with Apple Silicon, which is not generally published by Anza, so we need to generate this file and upload to our own AWS bucket for use in docker localnet setup:

    → solana-release-aarch64-unknown-linux-gnu.tar.bz2
4. For everything else, we can use the binaries published by Anza at [https://github.com/solana-labs/solana/releases](https://github.com/solana-labs/solana/releases)

## On Testnet

Agave is always BUILT FROM SOURCE directly on the host machine if it is intended for Solana Testnet.

## On Mainnet

Agave is always BUILT FROM SOURCE directly on the host machine if it is intended for Solana Mainnet.
