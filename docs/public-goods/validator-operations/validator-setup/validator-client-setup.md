# Validator Client Setup

### Common Setup Scenarios

When installing a validator there are several scenarios you might consider

* Setup a validator for the first time running a primary identity
* Setup a hot-spare validator to later swap validator hosts. See [upgrading-a-running-validator.md](upgrading-a-running-validator.md "mention")
* Upgrade a running validator without using a hot-spare host (will incurr in delinquency)

### Running the Setup Ansible Playbook

We will be using the playbook `pb_setup_validator_jito.yml` to setup a Jito-Solana client v3.0.2 with co-hosted relayer v0.4.2 on the host `validator-host` for our example. This validator will run a keyset named `demo-validator`.

#### Configuring the Inventory

Here is a typical inventory configuration:

```yaml
---
all:
  hosts:
    validator-host:
      ansible_host: 192.168.1.100
      ansible_port: 2522

  children:
    # ───── City Grouping ─────
    city_dal:
      hosts:
        validator-host:

    # ───── Network Grouping ─────
    solana:
      hosts:
        validator-host:

    # ───── Solana Cluster Grouping ─────
    solana_testnet:
      hosts:
        validator-host:

```

Replace the IP address with your real host IP address and match the city group based on the [jito Labs documentation](https://docs.jito.wtf/lowlatencytxnsend/#api). We have group vars for these cities: city\_dal, city\_lax, city\_man, city\_mia, city\_tlv, city\_waw. For more info on city grouping naming see: [#cities-and-countries](../../hayek-validator-kit/validator-conventions.md#cities-and-countries "mention")

Solana Cluster Grouping is essential to end up installing a validator node for the correct cluster.

#### Steps to run the playbook

1. Change to your local repo directory. If you haven't cloned the [hayek-validator-kit](https://app.gitbook.com/u/mWd8rWP4UVguErb6G6hVhYUW13D3) repo yet, do so by following these instructions [github-repo.md](../../hayek-validator-kit/github-repo.md "mention")
2. Connect to your Ansible Control. See [#connecting-to-ansible-control](../../hayek-validator-kit/ansible-control.md#connecting-to-ansible-control "mention")
3.  When the ansible control is ready, change to the `ansible` directory.\


    ```bash
    cd ansible
    ```

    \
    From there you can run the setup playbook. Here is a sample playbook run command to install Jito-Solana client co-hosted relayer in host `validator-host` \


    ```bash
    ansible-playbook playbooks/pb_setup_validator_jito.yml \
      -i solana_setup_host.yml \
      --limit validator-host \
      -e "target_host=validator-host" \
      -e "validator_name=demo-validator" \
      -e "validator_type=primary" \
      -e "solana_cluster=testnet" \
      -e "jito_version=3.0.2" \
      -e "jito_relayer_type=co-hosted" \
      -e "jito_relayer_version=0.4.2" \
      -e "build_from_source=true" \
      -e "use_official_repo=true"
    ```

    \
    Adjust parameters to match any other scenario.
4.  After setup is completed open a SSH session to your host to monitor validator startup and verify that the co-hosted relayer is working properly.\
    \
    Check validator process status\


    ```bash
    ps aux | grep agave-validator
    ```

    \
    Check the logs, conveniently in another SSH session for better situation awareness\


    ```bash
    tail -f ~/logs/agave-validator.log
    ```

    \
    Now monitor the validator startup process\


    ```bash
    agave-validator -l /mnt/ledger monitor
    ```

    \
    While the validator is starting up you can see several stages passing by, Connecting to RPC, Downloading snapshot, Loading ledger, Health check and slot processing status.\
    \
    To have a better understanding on what to look for when inspecting the logs see: [#initial-startup-monitoring](../metrics-and-monitoring/inspecting-logs.md#initial-startup-monitoring "mention") and for the Jito Relayer see: [#jito-relayer-logs](../metrics-and-monitoring/inspecting-logs.md#jito-relayer-logs "mention")
