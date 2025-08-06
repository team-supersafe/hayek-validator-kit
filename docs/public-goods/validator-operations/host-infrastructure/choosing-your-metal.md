---
description: How to choose your bare metal host to run a validator
---

# Choosing your metal

## Hardware Requirements

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

## Decentralization Scoring

Many Solana validator rankings (e.g. Validators.app, JSOL, Jito Score) reward validators that contribute to network-level decentralization. These "rewards" are usually rankings that have a direct impact in delegation incentives coming from [Stake Pools](../validator-stake/stake-pools.md) and [Delegation Programs](../validator-stake/sfdp.md).&#x20;

These rankings penalize central points of failure to decentralize the network across many dimensions, but four key ones come into play an important role when choosing your bare metal:&#x20;

### 1. ASN (Autonomous System Number)

* What it is: The network ID associated with your hosting provider or ISP.
* Why it matters: Too many validators under the same ASN (e.g. AS24940 for Hetzner) create single points of failure and routing risk.
* Best practice:
  * Avoid ASNs with large node population (e.g. TERASWITCH, OVH, AWS, GCP).
  * Prefer unique or lightly used ASNs.
  * Use [Validators.app ASN Map](https://validators.app/asn-map) to assess ASN concentration.

### 2. Data Center / Hosting Provider

* What it is: The physical facility where your node runs.
* Why it matters: Even under different ASNs, multiple validators in the same DC are subject to the same physical outages or maintenance windows.
* Best practice:
  * Avoid DCs with large node population (e.g. [20326-DE-Frankfurt am Main](https://www.validators.app/data-centers/20326-DE-Frankfurt%20am%20Main?locale=en\&network=mainnet), [20326-NL-Amsterdam](https://www.validators.app/data-centers/20326-NL-Amsterdam?locale=en\&network=mainnet), [396356-GB-London](https://www.validators.app/data-centers/396356-GB-London?locale=en\&network=mainnet)).
  * Colocate in diverse DCs or contract with smaller ISPs.
  * Check that the data center isn’t hosting >10 validators.

### 3. Geographic Location

* What it is: The continent, country, and city where the validator is hosted.
* Why it matters: Geographic diversity protects against region-specific threats—natural disasters, regulatory clampdowns, or network partitions.
* Best practice:
  * Avoid clustering in validator-heavy cities like Frankfurt, Amsterdam, or New York.
  * Spread nodes across continents, not just countries.
  * Tools like JSOL and Jito’s validator reports show clustering hotspots.

### 4. TPU IP Concentration (for Jito)

* What it is: The Transaction Processing Unit IP address your Jito relayer advertises to the world.
* Why it matters: Validators running the Jito client, and using a Shared Jito Relayer (as opposed to a co-hosted one) are also sharing the TPU IPs and create a single point of failure if that Relayer does down.
* Best practice:
  * Avoid using a shared Jito Relayer. Build and install your own and co-host it with the validator in the same bare metal.

#### Max Decentralization = Max Delegation

Validators who score high on decentralization are more likely to:

* Rank higher on delegation platforms
* Avoid slashing risks tied to shared failures
* Attract decentralization-focused delegators (Foundation, JSOL, stake pools)

## Mainnet vs Testnet

Solana Mainnet-Beta and Solana Testnet are the two networks you will most likely be configuring on your validator after it gets installed in your raw metal server. A general rule of thumb is to follow the Solana Foundation liveness requirements for the [Delegation Program](https://solana.org/delegation-program) as a litmus test of how much you should be provisioning and. what's expected of your servers.

A common setup is to have:

1. One host as the primary for Mainnet in ASN a1, DC d1, City c1
2. One host as the hot-spare of your primary in ASN a2, DC d2, City c2
3. One host as the primary for Testnet in ASN a3, DC d3, City c3

The key is to maintain enough variance across ASNs, DCs and Cities, such that, in the event of disaster, you can recover quickly by switching to your hot-spare, or in the worst-case scenario, repurposing the Testnet host.

## Provisioning

Most metal providers (e.g. Vultr, Edgevana, Latitude, etc.) force the provisioning of the server with the `ubuntu` user by default, as the SUDO user for sys-admins.

Once the server is provisioned, you must add your public SSH key to the `ubuntu` user so you can SSH into the server for further setup.

This is how:

1. a
2. b
3. c
4. d
5. e
