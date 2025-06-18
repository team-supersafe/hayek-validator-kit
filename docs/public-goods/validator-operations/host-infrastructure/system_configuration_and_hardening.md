---
description: Steps to configure and harden a newly provisioned server
---

# System Configuration and Hardening

## Prerequisites

Before starting the configuration and hardening process, ensure you have the following:

- **User Creation**: The Ansible playbook for creating and configuring server users must have been executed. For more details, see [Create Users on a New Server](create-users-new-box.md).
- **Development Environment**:
  - **Hayek .devcontainer**: This environment comes preconfigured with an `ansible-control` node and all necessary dependencies for management and automation.
  - **Visual Studio Code or Cursor Terminal**: Recommended for working with the devcontainer.
- Access to the server with administrative privileges (root or sudo).
- The server must have Simultaneous Multithreading (SMT) enabled.
- The server must have a minimum of 4 hard drives.

## Recommended Hardware Specifications

This configuration is based on the following recommended hardware specifications:

- **CPU**: 24 cores (AMD EPYC 9254)
- **RAM**: 384 GB or higher
- **Disks**:
  - NVMe 1: Ledger (1 TB+)
  - NVMe 2: Accounts (1 TB+)
  - NVMe/SSD 3: Snapshots
  - NVMe/SSD 4: Operating System
- **Network**: 10 Gbps
- **Operating System**: Ubuntu 24.04

## Repository Structure

For the server configuration and hardening process, we will use the following files:

```
ansible/
├── playbooks/
│   └── pb_setup_metal_box.yml      # Main playbook for server setup
├── roles/
│   └── server_initial_setup/       # Role containing all server configuration tasks
│       ├── files/                  # Configuration files
│       │   ├── 21-agave-validator.conf
│       │   ├── 90-solana-nofiles.conf
│       │   ├── 99-disable-ipv6.conf
│       │   ├── cpu-governor.service
│       │   └── health_check.sh
│       ├── handlers/               # Service handlers
│       │   └── main.yml
│       ├── tasks/                  # Main tasks
│       │   ├── cpu_isolation.yml
│       │   ├── disk_setup.yml
│       │   ├── initial_setup.yml
│       │   ├── main.yml
│       │   ├── precheck.yml
│       │   ├── restart_server.yml
│       │   ├── security.yml
│       │   └── system_tuning.yml
│       └── vars/                   # Variables
│           └── main.yml
└── solana_new_metal_box.yml        # Inventory file for the new server
```

### Key Components

## Configuration Variables

The following variables are used in the server configuration process:

| Variable | Description | Default Value |
|----------|-------------|---------------|
| `timezone` | Timezone configuration for the server | "America/New_York" |
| `sol_owner` | User configuration for Solana validator | "sol" |
| `cpu_config.isolated_cores` | CPU cores to be isolated | "2,26" |
| `cpu_config.irq_cores` | CPU cores for IRQ handling | "0-1,3-25,27-47" |
| `cpu_config.pstate` | CPU power state | "active" |
| `ssh_config.port` | SSH port | 2522 |
| `ssh_config.permit_root_login` | Allow root login | no |
| `ssh_config.pubkey_authentication` | Enable public key authentication | yes |
| `ssh_config.password_authentication` | Enable password authentication | no |
| `firewall.ssh_port` | SSH port for firewall | 2522 |
| `firewall.tcp_ports` | TCP ports to allow | [1234, 9090] |
| `firewall.tcp_ranges` | TCP port ranges to allow | [8000:8020] |
| `firewall.udp_ranges` | UDP port ranges to allow | [8000:8020] |
| `firewall.denied_ports` | Ports to deny | [8899, 8900] |
| `directory_permissions.mode` | Default directory permissions | '0755' |
| `directory_permissions.owner` | Default directory owner | "{{ sol_owner }}" |
| `directory_permissions.group` | Default directory group | "{{ sol_owner }}" |
| `mount_directories` | List of directories to mount | [ledger, accounts, snapshots] |
| `min_required_disks` | Minimum number of required disks | 3 |
| `mount_points.ledger` | Mount point for ledger data | "/mnt/ledger" |
| `mount_points.accounts` | Mount point for accounts data | "/mnt/accounts" |
| `mount_points.snapshots` | Mount point for snapshots | "/mnt/snapshots" |
| `filesystem_formats.ledger` | Filesystem format for ledger | "xfs" |
| `filesystem_formats.accounts` | Filesystem format for accounts | "xfs" |
| `filesystem_formats.snapshots` | Filesystem format for snapshots | "ext4" |
| `health_check.script_name` | Health check script name | "health_check.sh" |
| `health_check.dest_path` | Health check script destination | "/home/{{ sol_owner }}/{{ health_check.script_name }}" |
| `health_check.owner` | Health check script owner | "{{ sol_owner }}" |
| `health_check.group` | Health check script group | "{{ sol_owner }}" |
| `health_check.mode` | Health check script permissions | "0750" |

## Inventory Configuration

Before running the playbook, you need to update the inventory file `solana_new_metal_box.yml` with the correct IP address of the server to be configured:

```yaml
---
all:
  hosts:
    # Host for provisioning new servers
    # Add to appropriate groups before running playbooks
    new-metal-box:
      ansible_host: 192.168.1.100  # Replace with assigned IP
      ansible_port: 22
```

## Executing the Playbook

Before running the playbook, please note that the `ubuntu` user is no longer active. Therefore, you must execute the playbook using a sudo user. The playbook `pb_setup_metal_box.yml` is configured to run with a specific user:

```yaml
- name: Setup Metal Box Server
  hosts: new-metal-box
  user: dave
  become: true
```

Make sure to replace `dave` with your actual sudo user if different.

To execute the playbook, use the following command:

```sh
ansible-playbook -i solana_new_metal_box.yml playbooks/pb_setup_metal_box.yml -K
```

> **Note:** The `-K` flag is used to request sudo access. You will need the password of the user with which the playbook will be executed (e.g., `dave`).


