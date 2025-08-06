---
description: >-
  The physical infrastructure necessary to operate a high-performance,
  production-grade Solana validator using the Hayek Validator Kit
---

# Host infrastructure

## General Considerations

Running a performant validator requires reliable, optimized hardware paired with infrastructure automation. This guide outlines Hayek’s approach to provisioning and maintaining host infrastructure using Ansible.

## Validator Stack

At a high level, the validator stack looks like the following

Physical Hardware → OS and Networking → Solana Client (e.g., Solana Labs, Jito, Firedancer) → Monitoring/Logging → Backup & Recovery

## Choosing your metal

You cannot run testnet and mainnet Solana Validators using virtualized environments, as it will fall behind the rest of the network, no matter how much you think you can optimize it. Don't waste your time. But if you are hard-headed, don't come back asking why it doesn't work.

Explore the [Choosing Your Metal](choosing-your-metal.md) dedicated page for everything you need to know.

## Infrastructure Options

Most validator operators use Managed Infrastructure to rent bare metal servers from well-known ISNs and Data Centers. There's an entire section and science behind this decision and you should explore and be fully aware of the economic ramifications of choosing the right infra.&#x20;

Depending on your level of comfort, you are limited to these:

* On-prem / self-managed hardware: full control, but requires operations, maintenance and dedicated fiber network.
* Colocation: own hardware but hosted in a DC.
* Managed infrastructure / bare metal: service providers handling uptime, redundancy, expert support

## Security & Key Management

There are a lot of security best practices to be considered to run a Solana Validator like:

1. Least privilege for running Solana services and scripts as a dedicated non‑root user
2. Storing vote-account withdrawer keys offline or in multisig/hardware wallet, instead of keeping those keys in the server&#x20;
3. Minimize surface area with only required services running

As security is a cross-cutting concern, it is ever present across different pages in this documentation.&#x20;

## Best Practices & Further Resources

The best place to get information and continue to improve is the Solana Discord Server. It has many different dedicated channels for each topic and a very vibrant and helpful community of validator operators.&#x20;



&#x20;
