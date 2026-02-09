---
description: How to choose your bare metal host to run a validator
---

# Choosing Bare Metal

## Hardware Requirements

These are well maintained across different clients and the community in the following links:

1. [Anza's Hardware Recommendations](https://docs.anza.xyz/operations/requirements#hardware-recommendations)&#x20;
2. [Solana Hardware Compatibility List](https://solanahcl.org/) (Community Maintained - Open Source )
3. [Firedancer Hardware Requirements](https://docs.firedancer.io/guide/getting-started.html#hardware-requirements)

They roughly point at these recommended minimum requirements:

* CPU: 24+ physical cores (48+ threads) with AVX2
* RAM: 512 GB ECC DDR4/DDR5
* Disk config:
  * 2+  TB NVMe SSD for ledger
  * 2+ TB NVMe SSD for accounts
  * 300+ GB NVMe SSD for snapshots
  * 300+ GB NVMe SSD for the OS
* BIOS config:
  * RAID-0 (this may require you to create a support ticket with your metal provider)
* Network: 3 Gbps minimum, 10+ Gbps preferred
* Power: UPS and dual PSU recommended

{% hint style="success" %}
These specs aim to ensure your validator can stay in consensus, avoid delinquency, and perform well under high network load.
{% endhint %}

## Decentralization Scoring

Many Solana validator rankings (e.g. Validators.app, JPool, Jito Score) reward validators that contribute to network-level decentralization. These "rewards" are usually rankings that have a direct impact in delegation incentives coming from [Stake Pools](../revenue-and-performance/stake-pools.md) and [Delegation Programs](../revenue-and-performance/sfdp.md).&#x20;

Every ranking system is different, but they all penalize central points of failure to decentralize the network across many dimensions. Four of those dimensions come into play when choosing your bare metal:&#x20;

### 1. ASN (Autonomous System Number)

* What it is: The network ID associated with your hosting provider or ISP.
* Why it matters: Too many validators under the same ASN (e.g. [396356](https://www.validators.app/asns/396356?locale=en\&network=mainnet) for LATITUDE-SH) create single points of failure and routing risk.
* Best practice:
  * Avoid ASNs with large node population (e.g. TERASWITCH, LATITUDE-SH, OVH, AWS, GCP).
  * Prefer unique or lightly used ASNs.
  * Use [Validators.app ASN Map](https://validators.app/asn-map) to assess ASN concentration.

### 2. Data Center / Hosting Provider

* What it is: The physical facility where your node runs.
* Why it matters: Even under different ASNs, multiple validators in the same DC are subject to the same physical outages or maintenance windows.
* Best practice:
  * Avoid DCs with large node population (e.g. [20326-DE-Frankfurt am Main](https://www.validators.app/data-centers/20326-DE-Frankfurt%20am%20Main?locale=en\&network=mainnet), [20326-NL-Amsterdam](https://www.validators.app/data-centers/20326-NL-Amsterdam?locale=en\&network=mainnet), [396356-GB-London](https://www.validators.app/data-centers/396356-GB-London?locale=en\&network=mainnet)).
  * Colocate in diverse DCs or contract with smaller ISPs.
  * Use [Validators.app Data Center List](https://validators.app/asn-map) to assess DC concentration.

### 3. Geographic Location

* What it is: The continent, country, and city where the validator is hosted.
* Why it matters: Geographic diversity protects against region-specific threats—natural disasters, regulatory clampdowns, or network partitions.
* Best practice:
  * Avoid clustering in validator-heavy cities like Frankfurt, Amsterdam, or New York.
  * Spread nodes across continents, not just countries.
  * Use [JPOOL Stake Locations Concentration Tool](https://app.jpool.one/stake-locations) to see clustering hotspots.

### 4. TPU IP Concentration (for Jito)

* What it is: The Transaction Processing Unit IP address your Jito relayer advertises to the world.
* Why it matters: Validators running the Jito client, and using a Shared Jito Relayer (as opposed to a co-hosted one) are also sharing the TPU IPs and create a single point of failure if that Relayer does down.
* Best practice:
  * Avoid using a shared Jito Relayer. Build and install your own and co-host it with the validator in the same bare metal.

### Max Decentralization = Max Delegation

It is important to realize there are two (2) vectors in each decentralization metric:

1. **Stake Concentration**: usually expressed as a percentage of the total SOL staked in that ASN/DC/City/etc
2. **Population Concentration**: The number of unique nodes hosted in that ASN/DC/City/etc.

Although they are both important factors, Stake Concentration carries more weight than Population, since PoS and Leader Schedule only accounts for Stake distribution and not Population.

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

## Provisioning the box

Most metal providers (e.g. Vultr, Edgevana, Latitude, etc.) force the provisioning of the server with the `ubuntu` user by default, as the SUDO user for sys-admins.

Once the server is provisioned, you must add your public SSH key to the `ubuntu` user so you can SSH into the server for further setup.

### LATITUDE - Complete Provisioning

#### Recommended plan: m4.metal.large

{% hint style="success" %}
This configuration meets the requirements to operate a validator at full capacity for both Mainnet and Testnet environments.
{% endhint %}

**Server Creation**

1. Access panel: Login to Latitude.sh
2. Navigation: Left panel → Bare Metal
3. Create server: Upper right corner → + Create Server
4. Select plan: Choose m4.metal.large
5. Location:

* Select desired city
* If unavailable → Join Waitlist

{% hint style="info" %}
The city you desire might not be available at the moment. If the location is not available, you can join the waitlist.
{% endhint %}

**Technical Configuration**

**Operating System**

* OS: Ubuntu 24.04 LTS

**Billing Options**

One of the virtues that not all ASN providers have is the ability to contract servers by the hour. If you want to perform a Solana application update and need to temporarily create a hot spare, this is the best alternative.

* Hourly | Monthly | Yearly

**SSH Authentication**

Latitude offers the possibility to start the server using your public key or creating the server with a password for the ubuntu user. It's highly recommended to use SSH public key authentication.

* ✅ Recommended: SSH Public Key
* ❌ Not recommended: Password for ubuntu user
* New key: If you don't have a key → Click New → Add your public key

**RAID Configuration**

* ✅ Select: No RAID
* Available options: No RAID, RAID 0, RAID 1
* Important: Configuration optimized for `No RAID`

**Finalization**

1. Server name: Follow defined naming convention
2. Deploy: Click Deploy

### Post-Provisioning Verifications

It's recommended before starting to configure the server, users, hardware and system tuning, to review some configurations.

#### **Verify RAID Configuration**

```bash
# Method 1: Check disk structure
lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT

# Method 2: Check RAID status
cat /proc/mdstat
```

Expected output:

```bash
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
unused devices: <none>
```

{% hint style="warning" %}
Make sure the server doesn't have any RAID configuration. We have encountered cases where you request the server with NO RAID and the provider provisions it with RAID 1, especially in locations like MIA.
{% endhint %}

#### **Verify SMT (Simultaneous Multithreading)**

You must also ensure that the server has SMT active. By running htop you will see the number of cores - on this server you should see 48 instead of 24.

```bash
# Check available threads
htop
```

#### **Verify CPU Governor**

```bash
# Check CPU frequency drivers
ls /sys/devices/system/cpu/cpu0/cpufreq
```

Expected output (driver):

* ✅ amd\_pstate&#x20;
* This is the most efficient driver, and the recommended one for Solana

If `amd_pstate` is not present, check for its fallback:

```bash
# check if acpi-cpufreq is in use
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
```

Expected output

* `acpi-cpufreq`&#x20;
* This driver is the fallback when amd\_pstate is not availble. It is less efficient, for when amd\_pstate is missing. Ok for hot-spare servers.

{% hint style="warning" %}
If none of the drivers listed above exist, you can either Delete the metal box and get a new one to see if you get lucky, OR contact support to activate these drivers in the BIOS
{% endhint %}

**Performance Optimization:** Another verification you can do is to ensure that Governor is active, so that the kernel is assigned to manage CPU frequency and not BIOS. If you don't see any active driver, it's necessary to access the BIOS and activate it. One of the drivers you should see is amd\_pstate.

**Hardware Compatibility**: In case it's not available, you must contact the provider directly because some motherboard firmware doesn't have this driver available, and it's necessary to replace the server with one that can activate it. This driver is more efficient than the one that comes predetermined by the kernel, so it's recommended to activate it to obtain maximum server performance.

### &#x20;EDGEVANA - Complete Provisioning

#### Provisioning Process

1. Login: [Access Edgevana](https://nodes.edgevana.com/dashboard)
2. Create server: Upper right corner → + button (blue) → Bare Metal
3. Purpose: Select Solana Mainnet
4. CPU: Select the same as Latitude (AMD 6254)

**Purpose-Based Selection:** In the new screen, select the server purpose, where they will recommend servers that fit based on this purpose. For example, select "Solana Mainnet". For CPU, select the desired one which is the same we selected in Latitude.

**Automatic Configuration**

* RAM: Same amount as Latitude (384GB)
* Disks: Similar configuration to Latitude
* ⚠️ Particularity: Automatically provision with RAID 1

#### **RAID Configuration (Required)**

One of the particularities with Edgevana is that there's no option to select your preferred RAID type during the provisioning process. The provider automatically configures all servers with RAID 1, regardless of your specific requirements. To address this limitation, you must contact their support team directly and explicitly request that they disable RAID on the server you just provisioned. This process typically takes approximately 30 minutes to complete. It's important to make this request immediately after provisioning to minimize any delays in your server setup timeline, as this RAID configuration change is essential for optimal validator performance and matches the storage configuration used in our deployment scripts.

#### **Authentication**

Once they provision the server, you must initialize the server with your public key. This provider doesn't give you the possibility to select between SSH key or user and password. Good for them!

### Post-Provisioning Verifications Edgevana

**Access Limitations**

* ❌ No BIOS access: No direct BIOS access
* Solution: Contact support for:
* Activate Hyper-Threading
* Configure CPU Governor

Once the server is provisioned, you can access it and run the same prechecks, but with the particularity that this provider doesn't give you access to BIOS, so you will have to contact support to activate these requirements in BIOS such as Hyper-Threading and CPU Governor.
