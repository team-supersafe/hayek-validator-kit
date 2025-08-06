---
description: How to choose your bare metal host to run a validator
---

# Choosing your metal

### Hardware Requirements

These are well maintained across different clients and the community in the following links:

1. [Anza's Hardware Recommendations](https://docs.anza.xyz/operations/requirements#hardware-recommendations)&#x20;
2. [Solana Hardware Compatibility List](https://solanahcl.org/) (Community Maintained - Open Source )
3. [Firedancer Hardware Requirements](https://docs.firedancer.io/guide/getting-started.html#hardware-requirements)

They roughly point at these recommended minimum requirements:

* CPU: 24+ physical cores (48+ threads) with AVX2
* RAM: 512 GB ECC DDR4/DDR5
* Disk:
  * 2 TB NVMe SSD for ledger
  * 1 TB NVMe SSD for accounts
  * Optional: separate OS drive
* Network: 3 Gbps minimum, 10+ Gbps preferred
* Power: UPS and dual PSU recommended

> 🎯 _These specs aim to ensure your validator can stay in consensus, avoid delinquency, and perform well under high network load._

### ASN Concentration

add

### Data Center Concentration

add

### Location Concentration

add

### TPU IP Concentration

add

## Provisioning

Most metal providers (e.g. Vultr, Edgevana, Latitude, etc.) force the provisioning of the server with the `ubuntu` user by default, as the SUDO user for sys-admins.

Once the server is provisioned, you must add your public SSH key to the `ubuntu` user so you can SSH into the server for further setup.

This is how:

1. a
2. b
3. c
4. d
5. e
