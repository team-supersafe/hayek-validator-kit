# Ansible Inventories

This directory contains the consolidated inventory files for the Solana validator setup. All real IP addresses have been replaced with documentation-friendly private network IPs (192.168.x.x) except for the localnet cluster which uses 172.25.0.x addresses.

## Inventory Files

### 1. `solana_new_metal_box.yml`

**Purpose**: Initial host preparation phase
**Use Case**: When a new host is provisioned in the datacenter
**Playbooks**:

- `pb_setup_metal_box.yml`
- `pb_setup_server_users.yml`

**Features**:

- Single host inventory
- No group vars grouping needed
- Generic placeholder IP (192.168.1.200)
- Operators must replace with actual assigned IP before use

**Usage**:

```bash
# Update the IP address in the inventory file
# Then run the playbooks
ansible-playbook -i solana_new_metal_box.yml playbooks/pb_setup_metal_box.yml
ansible-playbook -i solana_new_metal_box.yml playbooks/pb_setup_server_users.yml
```

### 2. `solana_setup_host.yml`

**Purpose**: Single host target playbooks
**Use Case**: Installing software and configuring a single validator host
**Playbooks**:

- `pb_install_rust.yml`
- `pb_install_solana_cli.yml`
- `pb_setup_validator_jito.yml`
- `pb_install_validator_keyset.yml`

**Features**:

- Single host inventory
- Generic hostname (validator-host)
- Operators must replace the `validator-host` entry with the actual host name following the [Naming Conventions](https://docs.hayek.fi/dev-public-goods/hayek-validator-kit/validator-conventions)
- Documentation-friendly IP (192.168.1.100)
- Operators must replace with actual host IP before use
- Includes datacenter, city, network, and cluster groupings

**Usage**:

```bash
# Update the IP address in the inventory file
# Then run any of the single-host playbooks
ansible-playbook -i solana_setup_host.yml playbooks/pb_install_rust.yml
ansible-playbook -i solana_setup_host.yml playbooks/pb_install_solana_cli.yml
ansible-playbook -i solana_setup_host.yml playbooks/pb_setup_validator_jito.yml
ansible-playbook -i solana_setup_host.yml playbooks/pb_install_validator_keyset.yml
```

### 3. `solana_two_host_operations.yml`

**Purpose**: Two-host (Source → Destination) playbooks
**Use Case**: Hot swap operations requiring source and destination hosts
**Playbooks**:

- `pb_hot_swap_validator_debug.yml`
- `pb_hot_swap_validator_hosts.yml`

**Features**:

- Two host inventory (source-host, destination-host)
- Operators must replace `source-host` and `destination-host` entries with the actual host names that will be involved following the [Naming Conventions](https://docs.hayek.fi/dev-public-goods/hayek-validator-kit/validator-conventions)
- Documentation-friendly IPs (192.168.1.10, 192.168.1.11)
- Operators must replace with actual source/destination host IPs before use
- Includes datacenter, city, network, and cluster groupings

**Usage**:

```bash
# Update the IP addresses in the inventory file
# Then run the two-host playbooks
ansible-playbook -i solana_two_host_operations.yml playbooks/pb_hot_swap_validator_debug.yml
ansible-playbook -i solana_two_host_operations.yml playbooks/pb_hot_swap_validator_hosts.yml
```

## IP Address Ranges Used

- **192.168.1.x**: Documentation-friendly private network IPs for production hosts
- **172.25.0.x**: Localnet cluster IPs (preserved for local development)

## Localnet Cluster Reference

The localnet cluster runs in a Dev container with a fixed configuration. Use this reference when creating inventories for localnet operations:

```yaml
---
all:
  hosts:
    host-alpha:
      ansible_host: 172.25.0.11
      ansible_port: 22
    host-bravo:
      ansible_host: 172.25.0.12
      ansible_port: 22
    host-charlie:
      ansible_host: 172.25.0.13
      ansible_port: 22

  children:
    # ───── City Grouping ─────
    city_dal:
      hosts:
        host-alpha:
        host-bravo:
        host-charlie:

    # ───── Network Grouping ─────
    solana:
      hosts:
        host-alpha:
        host-bravo:
        host-charlie:

    # ───── Solana Cluster Grouping ─────
    solana_localnet:
      hosts:
        host-alpha:
        host-bravo:
        host-charlie:
```

**Usage for Localnet Operations**:

```bash
# Create a temporary inventory file with the above content
# Then run playbooks against localnet hosts
ansible-playbook -i localnet_inventory.yml playbooks/pb_hot_swap_validator_debug.yml
```

## Before Running Playbooks

**IMPORTANT**: Before executing any playbook, operators must:

1. **Update IP Addresses**: Replace the documentation IPs with actual host IPs
2. **Verify Hostnames**: Ensure hostnames match your actual infrastructure
3. **Check Group Assignments**: Verify hosts are assigned to appropriate groups if needed

## Example: Updating Inventory for Production

```yaml
# Before (documentation)
validator-host:
  ansible_host: 192.168.1.100
  ansible_port: 22

# After (production)
validator-host:
  ansible_host: 203.0.113.10  # Your actual validator IP
  ansible_port: 22
```

## Removed Inventories

The following inventories were consolidated and removed:

- `solana_hot_swap.yml` → functionality moved to `solana_two_host_operations.yml`
- `solana_testnet.yml` → functionality moved to `solana_setup_host.yml`
- `solana_localnet.yml` → configuration documented in README for reference

This consolidation reduces complexity while maintaining all necessary functionality for different operational phases.
