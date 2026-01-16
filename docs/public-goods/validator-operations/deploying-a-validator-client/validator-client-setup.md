# Validator Client Setup

## Setup Scenarios

When installing a validator there are two main scenarios you need to consider:

1. <mark style="background-color:blue;">**Scorched-Earth Setup**</mark>: Override a target host with a validator setup. This is good for:
   1. Setup a validator for the first time (override/repurpose the server host as a Solana validator)
   2. Upgrade a running validator without using a hot-spare host (will incurr in delinquency)
2. <mark style="background-color:blue;">**Hot-Spare Setup**</mark>: Setup a hot-spare validator to swap with a primary validator host. This is good for upgrading software and hardware with minimum downtime, such as:
   1. Upgrading hardware on a Mainnet validator
   2. Upgrading software version on a Mainnet validator
   3. Moving the validator to different Geo/ASN/DC

The following diagram shows the main difference between the Scorched-Earth and Hot-Spare Setups:

<figure><img src="../../.gitbook/assets/image (1).png" alt=""><figcaption></figcaption></figure>

## Readiness Checks

Irrespective of which setup you want to run, it is recommended you check that certain requirements are met with our built-in health checks:

### Host Health Check

Before proceeding with the installation, it is crucial to run the `health_check.sh` script to verify that the target host meets all the necessary requirements for a Solana validator. This script performs a series of checks on the system's hardware, operating system, and configuration.

To run the check, execute the following command:

```bash
bash /home/sol/health_check.sh
```

A successful check will display a summary with no errors, similar to the following screenshot.\
<img src="../../.gitbook/assets/image (1) (1).png" alt="" data-size="original">

If the script detects any issues (like in the following screenshot), it will provide a FAIL message along with a recommended action to resolve the problem. The script is designed to run all checks and report all failures, so you can address multiple issues at once.\
<img src="../../.gitbook/assets/image (3).png" alt="" data-size="original">

The script verifies several key requirements are met on the host, such as Processor (CPU) instruction set, Memory (RAM), Storage, OS configurations, and Network throughput and connectivity.

### Host Troubleshooting

The health check script is a diagnostic tool, so any failures it reports should be addressed before continuing. While the script provides solutions, here are some common issues and their resolutions:

* `FAIL: Automatic update services are enabled`
  * Description: This is a common error that occurs when the system's package manager (e.g., `dnf-automatic`, `unattended-upgrades`) is configured to apply updates automatically. This is a problem because an automatic reboot could cause the validator to go offline and become delinquent.
  * Solution: The script's output will provide the exact commands to disable the service depending on your operating system (e.g., `sudo systemctl disable --now unattended-upgrades`).
* Hardware-related failures
  * Description: Issues such as insufficient RAM, a non-ECC motherboard, not enough CPU cores available or base frequency below the requirements, or a lack of specific CPU instruction sets or will result in a failure. These are often difficult to fix with simple commands.
  * Solution: For non-compliant hardware or incorrect BIOS configurations, you will need to contact your data center or hardware support team. These issues are outside the scope of software configuration and require a physical or remote change to the hardware setup.

Visit the official documentation to know the [Hardware Recommendations](https://docs.anza.xyz/operations/requirements#hardware-recommendations) for a Validator and RPC Node Hardware Setups

### Network Health Check

Ensure that the network cluster delinquency is lower than the requirement set by Solana on the official communication channels before starting the installation. This is usually a percentage, like 3% or 5%, depending on the upgrade path:

1. **Official Communication Channels**: Monitor the Solana Tech Cluster announcements on Discord for [Mainnet](https://discord.com/channels/428295358100013066/669406841830244375), [Testnet](https://app.gitbook.com/u/mWd8rWP4UVguErb6G6hVhYUW13D3), and [Devnet](https://discord.com/channels/428295358100013066/749059399875690557).
2.  **Current Delinquent Stake**: Check the actual delinquent stake percentage in the cluster using the Solana CLI tool (use `-ut` for testnet `-ud` for devnet, and \* `-um` or no flag for mainnet):<br>

    ```bash
    solana validators -ut | grep "Delinquent Stake"
    ```

## Scorched-Earth Setup

The following choices will determine how to run the command to execute the playbook to setup a validator. The actual command uses placeholders to refer to these choices to easily copy the command template and just replace the placeholders with each decision you made.

### Validator Name & Type

**\<validator\_name>**\
&#xNAN;_&#x54;he validator name will reference the identity of the validator for the rest of its life from the moment it is first created so you might want to plan for a memorable, meaningful, short name. Consider only alphanumeric characters and dash or underscore characters._ [#naming-validators](../../hayek-validator-kit/ansible-control.md#naming-validators "mention")

**\<validator\_type>**\
&#xNAN;_&#x54;hese can be: primary, hot-spare. The primary identity should hold balance and stake enough to be able to participate in consensus. The hot-spare doesn't need to have neither balance nor stake, it comes handy for the_ [#hot-spare-setup](validator-client-setup.md#hot-spare-setup "mention")

### Cluster, Client & Version

**\<solana\_cluster>**\
&#xNAN;_&#x54;hese can be: mainnet, testnet, devnet, localnet_

**\<validator\_client>**\
&#xNAN;_&#x54;hese can be: agave, jito, firedancer, frankendancer_

**\<validator\_client\_version>**\
&#xNAN;_&#x54;o keep informed on the latest client releases visit these Solana Tech Cluster announcements' Discord channels:_ [_mainnet_](https://discord.com/channels/428295358100013066/669406841830244375)_,_ [_testnet_](https://discord.com/channels/428295358100013066/594138785558691840) _and_ [_devnet_](https://discord.com/channels/428295358100013066/749059399875690557)

### Relayer Type & Version

{% hint style="info" %}
You only need to pick the relayer config if you are installing the Jito Client.&#x20;
{% endhint %}

**\<relayer\_type>**\
&#xNAN;_&#x54;hese can be: shared, co-hosted. The Jito Transaction Relayer is a Transaction Processing Unit (TPU) proxy for MEV-powered Solana validators._

**\<relayer\_version>**\
&#xNAN;_&#x54;o keep informed on latest releases of the relayer visit the Jito-Solana_ [_validator-announcements_](https://discord.com/channels/938287290806042626/1148261936086142996) _Discord channel_

### Configure Inventory

Here is a typical inventory configuration template:

```yaml
---
all:
  hosts:
    validator_host:
      ansible_host: 192.168.1.100
      ansible_port: 2522

  children:
    # ───── City Grouping ─────
    city_dal:
      hosts:
        validator_host:

    # ───── Network Grouping ─────
    solana:
      hosts:
        validator_host:

    # ───── Solana Cluster Grouping ─────
    solana_testnet:
      hosts:
        validator_host:

```

Replace the `validator_host` with the target host name, replace the host IP address with your real target host's IP address and match the city group based on the [Jito Labs documentation](https://docs.jito.wtf/lowlatencytxnsend/#api). We have group vars for these cities: city\_dal, city\_lax, city\_man, city\_mia, city\_tlv, city\_waw. For more information on city grouping naming see: [#cities-and-countries](../../hayek-validator-kit/validator-conventions.md#cities-and-countries "mention")

Solana Cluster Grouping is essential to end up installing a validator node for the correct cluster.

### Run Playbook

1. Change to your local repo directory. If you haven't cloned the [hayek-validator-kit](https://app.gitbook.com/u/mWd8rWP4UVguErb6G6hVhYUW13D3) repo yet, do so by following these instructions [github-repo.md](../../hayek-validator-kit/github-repo.md "mention")
2. Connect to your Ansible Control. See [#connecting-to-ansible-control](../../hayek-validator-kit/ansible-control.md#connecting-to-ansible-control "mention")
3. When the Ansible control is ready, open an SSH connection from your Ansible Control to the target host to add the fingerprint to our known hosts to avoid access permission problems when running the playbook, this will also ensures proper connectivity to the destination host.
4.  Change to the `ansible` directory.<br>

    ```bash
    cd ansible
    ```

    \
    To run the playbook for  `validator_client = agave` use this command template replacing all `<placeholders>` with the actual choice for each placeholder:<br>

    ```bash
    ansible-playbook playbooks/pb_setup_validator_agave.yml \
      -i solana_setup_host.yml \
      --limit <validator_host> \
      -e "target_host=<validator_host>" \
      -e "validator_name=<validator_name>" \
      -e "validator_type=<validator_type>" \
      -e "solana_cluster=<solana_cluster>" \
      -e "build_from_source=true" \
      -e "use_official_repo=true"
    ```

    \
    To run the playbook for  `validator_client = jito` use this command template replacing all `<placeholders>` with the actual choice for each placeholder:<br>

    ```bash
    ansible-playbook playbooks/pb_setup_validator_jito.yml \
      -i solana_setup_host.yml \
      --limit <validator_host> \
      -e "target_host=<validator_host>" \
      -e "validator_name=<validator_name>" \
      -e "validator_type=<validator_type>" \
      -e "solana_cluster=<solana_cluster>" \
      -e "jito_version=<validator_client_version>" \
      -e "jito_relayer_type=<relayer_type>" \
      -e "jito_relayer_version=<relayer_version>" \
      -e "build_from_source=true" \
      -e "use_official_repo=true"
    ```

### Check Validator Health

After the validator software is correctly installed, the validator has to join the cluster and start voting. This involves multiple steps that happen in parallel, and automated ways, but with multiple failure points possible (mostly due to network conditions and the capacity of the validator to keep up with the rest of the network).

To check this process after your setup is completed, open a SSH session to your host to monitor validator startup and verify that the co-hosted relayer is working properly.

{% code title="Check validator process status" %}
```shellscript
ps aux | grep agave-validator
```
{% endcode %}

{% code title="Check the logs (tip: use a different SSH session for better situational awareness)" %}
```bash
tail -f ~/logs/agave-validator.log
```
{% endcode %}

To have a better understanding on what to look for when inspecting the logs see: [#initial-startup-monitoring](../metrics-and-monitoring/inspecting-logs.md#initial-startup-monitoring "mention") and for the Jito Relayer see: [#jito-relayer-logs](../metrics-and-monitoring/inspecting-logs.md#jito-relayer-logs "mention")

{% code title="Monitor the validator startup process" %}
```bash
agave-validator -l /mnt/ledger monitor
```
{% endcode %}

While the validator is starting up you can see several stages passing by, Connecting to RPC, Downloading snapshot, Loading ledger, Health check and slot processing status. This is known as the catchup process.

The monitor process runs indefinitely showing the slot processing status. Here is how slot processing status looks like:

```bash
$ agave-validator -l /mnt/ledger/ monitor
Ledger location: /mnt/ledger/
Identity: hyt8ZV8sweXyxva1S9tibC4iTaixfFfx8icpGXtNDUJ
Genesis Hash: 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY
Version: 3.0.2
Shred Version: 9065
Gossip Address: 67.213.118.77:8001
TPU Address: 67.213.118.77:11222
⠉ 160:31:18 | Processed Slot: 359481063 | Confirmed Slot: 359481063 | Finalized Slot: 359481029 | Full Snapshot Slot: 358092557 | Incremental Snapshot Slot: 358103854 | Transactions: 636783949018 | ◎116.007341756
```

If you get connection errors see [#agave-monitor](client-troubleshooting.md#agave-monitor "mention")

Typically if you are a few thousand slots behind or more, unless you have a really good hardware, it might not be feasible to catch up. Watch [THIS VIDEO](https://youtu.be/HKR5dn5CSZo?si=F19E4xtqqKgd7kUm\&t=1974) if you get stuck here.

Snapshot finder tool: [https://github.com/c29r3/solana-snapshot-finder](https://github.com/c29r3/solana-snapshot-finder) This is a python script that tests a bunch of RPC endpoints that are open to check what the best download speed is and then downloads the snapshot from that one.

### Troubleshooting

#### What to do if you can't catch up <a href="#what-to-do-if-you-cant-catch-up" id="what-to-do-if-you-cant-catch-up"></a>

* See [https://youtu.be/HKR5dn5CSZo?si=Kmul5ry-tsstZ0QL\&t=1958](https://youtu.be/HKR5dn5CSZo?si=Kmul5ry-tsstZ0QL\&t=1958)
* Wait! Catchup rate is variable and l've seen it improve very quickly after falling for a while
* Remove `-no-snapshot-fetch` and download a new snapshot (you will have a hole in your validator's ledger)
* Manually download a snapshot [https://github.com/c29r3/solana-snapshot-finder](https://github.com/c29r3/solana-snapshot-finder) is popular

#### Possible Reasons for falling behind (can't catch up) <a href="#possible-reasons-for-falling-behind-cant-catch-up" id="possible-reasons-for-falling-behind-cant-catch-up"></a>

* See [https://youtu.be/HKR5dn5CSZo?si=xvu47Bcre3L3jF2f\&t=2120](https://youtu.be/HKR5dn5CSZo?si=xvu47Bcre3L3jF2f\&t=2120)
* Snapshots you are downloading are too old (try using known validator, increase minimal download speed, snapshot finder)
* If snapshot is good, but you still can't catch up, it's likely a hardware perf issue
  * Check CPU, Thermal Design Power (TDP), NVMe drives, IOPS, Network, etc.
  * Try another server for a month?
  * Consider upgrading

When monitor stage "Loading ledger" finishes you can use the following command to see the catchup rate in detail (use `-ut` for testnet `-ud` for devnet, and `* -um` or no flag for mainnet):

Typical output (while catching up and when is fully caughtup):

```bash
solana catchup -ut --our-localhost 8899
# ⠄ 77 slot(s) behind (us:320589449 them:320589526), our node is gaining at 6.0 slots/second (AVG: 5.0 slots/second, ETA: slot 320589524 in 

solana catchup -ut --our-localhost 8899
# hytUYBP59GaVyiqG2ebrDozwoziVd17V5HYRPHp5R2W has caught up (us:320587019 them:320587015)
```

See [#check-catchup-speed](client-troubleshooting.md#check-catchup-speed "mention")

## Hot-Spare Setup

This setup is used when we want to achieve minimum downtime of the validator by preparing a hot-spare host with the desired state, and then migrating the primary identity to it.

`validator_name`: This is the name of your validator and serves to logically group the associated keyset.

`primary-host`: The host running your the keyset for your `validator_name`, which has the target validator identity we want to upgrade.

`hot-spare-host`: This is the hot spare for the primary host. We’ll install the desired client software version here, and once it’s ready, migrate the validator keyset over.

Steps to upgrade a validator client with a host-spare host:

1. Run a [Scorched-Earth Setup](validator-client-setup.md#scorched-earth-setup) on your `hot-spare-host` with the desired client and version. The configuration should use the `validator_name` keyset, but using the `hot-spare-identity` as the primary identity on the `hot-spare-host`. See [Validator Name & Type](validator-client-setup.md#validator-name-and-type)&#x20;
2. Run "pb\_hot\_swap\_validator\_hosts" between `primary-host` ↔️  `hot-spare-host`&#x20;
3. Monitor `validator_name` on its new host (`hot-spare-host`), which is now the `primary-host` for the validator.

At times it may be necessary to continue using the same host in Mainnet due to preferences in ASN, Geo, or Data Center, or simply because it was pre-paid for a year at a better rate. If this is the case, you can run a 2x Hot-Spare Setup to restore your validator to your original host:

<figure><img src="../../.gitbook/assets/image (2).png" alt="" width="375"><figcaption></figcaption></figure>
