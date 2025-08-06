---
description: Get up and running with the Hayek Validator Kit’s local environment in minutes
icon: rectangle-terminal
---

# Hayek Public Goods

The Hayek Validator Kit is an open source public good for developers and sysadmins that want to run high performance Solana validators. It is a pre-configured toolkit that includes automation, dev ops, virtualization services, a local environment, key management tools, and monitoring utilities — everything you need to deploy, test, and operate a validator in Localnet, Testnet and Mainnet environments.

See the [Github Repo](hayek-validator-kit/github-repo.md) page to view how to use and contribute to the Hayek Validator Kit.

## Quickstart Setup

### Step 1: Prepare Your Machine

Start by following the [Workstation Setup](hayek-validator-kit/workstation-setup.md) guide to ensure your system has the required tools and dependencies.

### Step 2: Clone the Repository

```bash
git clone https://github.com/team-supersafe/hayek-validator-kit.git
cd hayek-validator-kit
```

### Step 3: Run Solana Localnet

To spin up a local testnet environment:

```
./scripts/run-localnet.sh
```

This will start a local Solana network called Localnet with all of the Hayek Validator Kit components running in Docker.

***

### What’s Next?

Use the menu on the left to explore the rest of the documentation. If you’re just experimenting, localnet is all you need. If you’re going live, follow the full setup under Validator Operations.
