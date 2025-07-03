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

## Specific Configurations by Provider

### Latitude
- **Servers identified as m4.metal.large**
- Select servers without default RAID configuration

### Edgevana
- Come preconfigured with RAID 1 on the operating system disks
- To remove this RAID configuration, it is necessary to contact the support team
- The reinstallation and RAID removal process takes approximately 30-40 minutes

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

### Confirmation Step

After you run the playbook, you will see a confirmation message similar to the following:

```
TASK [Show server IP and request confirmation] ******************************************************
[Show server IP and request confirmation]
IMPORTANT: You are about to run this playbook on the server with IP: 192.168.1.100

To continue, please type exactly this IP: 192.168.1.100

If you are not sure, press Ctrl+C to cancel.

Type IP here
```

This step is a safety measure to ensure you are provisioning the correct server.

- Type the IP address shown to continue.
- If you are not sure, press Ctrl+C to cancel the process.

## Installation Process

Once the IP address is confirmed as correct, the playbook begins executing the necessary tasks starting with the prechecks. The process continues through all the configuration steps until it culminates by asking the user if they want to restart the server after the installation is complete.

### Final Step - Server Restart

After all configuration tasks are completed, the playbook will prompt the user with the following message:

```
TASK [server_initial_setup : Ask if you want to restart the server] ***************************
[server_initial_setup : Ask if you want to restart the server]
Do you want to restart the server now? (y/n):
```

If you confirm that you want to restart the server, it will display the following message:

```
TASK [server_initial_setup : Display reconnection instructions] *******************************
ok: [new-metal-box -> localhost] => {}

MSG:

-------------------------------------------------
THE SERVER IS NOW RESTARTING

To reconnect, please use:
ssh username@198.168.1.100 -p 2522

Please allow a few minutes for the server to complete the restart.
-------------------------------------------------
```

{% hint style="info" %}
**Important:** After the server restarts, you must access it via SSH using port 2522.
{% hint style="warning" %}

### Post-Restart Verification

Once the server has restarted, it is recommended to access it and verify that all configurations were applied correctly. To do this:

1. **Access the server**: Connect via SSH

```sh
ssh -P 2522 dave@192.168.1.100
```

2. **Navigate to the home directory**: `cd /home/sol/`
3. **Run the health check script**: `bash health_check.sh`

This script will verify that all the configurations have been applied correctly and the server is ready for Solana validator operations.

## What the Playbook Does

The following sections detail all the tasks and configurations that the playbook performs after the IP confirmation. These tasks are executed in sequence to ensure the server is properly configured and hardened for Solana validator operations.

### Prechecks Executed by the Playbook

After confirming the IP, the playbook runs a series of prechecks to validate various aspects of the setup:

#### CPU Configuration Checks

- **Check CPU Governor**: Verifies that the CPU governor is set to performance mode.
- **Check CPU Scaling Driver**: Ensures that the CPU is using the p-state driver.
- **Check AMD SMT/Hyperthreading**: Confirms that AMD SMT/Hyperthreading is enabled.

#### Disk Configuration Checks

- **Get System Disk**: Identifies the system disk.
- **Check Available Disks**: Lists available disks, sorted by size, and excludes the system disk.
- **Verify Minimum Number of Disks**: Ensures that there are at least the required number of disks for ledger, accounts, and snapshots.
- **Verify Mount Points**: Checks that the required mount points are not already mounted.

> **Note:** The playbook verifies that the server has at least 3 hard drives available, depending on the value of the `min_required_disks` variable. Currently, it is required to have at least 3 disks: one for accounts, one for ledger, and one for snapshots.

{% hint style="warning" %}
If the playbook detects that the disks are already mounted in `/mnt/account`, `/mnt/ledger`, or `/mnt/snapshots`, it will throw an error to prevent execution on a production server. If you need to run this on a production server, you must manually unmount the disks using the following command:
>
> ```sh
> umount /mnt/ledger /mnt/account /mnt/snapshots
> ```

{% hint style="warning" %}

## Initial Configurations

The playbook performs the following initial system setup tasks:

### Package Management
- **Update and Upgrade**: Updates the apt cache and upgrades all packages with autoclean and autoremove.
- **Disable Unattended Upgrades**: Stops and disables the unattended-upgrades service to prevent automatic updates.
- **Install Essential Packages**: Installs essential packages including `htop`, `fail2ban`, `hwloc`, and `xfsprogs` for XFS filesystem operations.

> **Note:** `hwloc` (Hardware Locality) is used to discover and display the hierarchical topology of the system, including NUMA nodes, CPU cores, and cache information. This is particularly useful for optimizing Solana validator performance by understanding the hardware layout and ensuring proper CPU core isolation.

## Disk Setup

The playbook performs comprehensive disk setup and configuration for the Solana validator:

### Disk Assignment
- **Automatic Assignment**: Disks are automatically assigned by size, with the largest disk assigned to ledger, the second largest to accounts, and the third largest to snapshots.

### Storage Setup
- **Disable Swap**: Disables swap to prevent performance issues that could affect validator performance.
- **Format Drives**: Formats each drive with the appropriate filesystem:
  - Ledger: XFS filesystem
  - Accounts: XFS filesystem
  - Snapshots: ext4 filesystem

### Mount Configuration
- **Create Mount Points**: Creates the necessary mount point directories (`/mnt/ledger`, `/mnt/accounts`, `/mnt/snapshots`).
- **Configure fstab**: Sets up automatic mounting using UUIDs with optimized mount options:
  - Ledger: `defaults,noatime,logbufs=8,logbsize=32k`
  - Accounts: `defaults,noatime`
  - Snapshots: `defaults,noatime`
- **Mount Filesystems**: Mounts all configured filesystems and sets correct ownership and permissions. The owner is configured as the `sol` user.

## CPU Isolation

The playbook configures CPU isolation to optimize performance for the Solana validator:

### CPU Topology
- **Install hwloc**: Installs the `hwloc` package to provide CPU topology information and tools like `lstopo`.

### GRUB Configuration
- **Configure Boot Parameters**: Updates the GRUB configuration with CPU isolation parameters:
  - `amd_pstate={{ cpu_config.pstate }}`: Sets the AMD power state (default: "active")
  - `nohz_full={{ cpu_config.isolated_cores }}`: Disables timer ticks on isolated cores
  - `isolcpus=domain,managed_irq,{{ cpu_config.isolated_cores }}`: Isolates specific CPU cores from the scheduler
  - `irqaffinity={{ cpu_config.irq_cores }}`: Sets which cores handle interrupt requests

### Default Configuration
- **Isolated Cores**: Cores 2 and 26 are isolated for the Solana validator
- **IRQ Cores**: Cores 0-1, 3-25, and 27-47 handle interrupt requests

> **Note:** The CPU isolation is specifically designed for Proof of History (PoH) optimization. Cores 2 and 26 are isolated because core 2 is typically the nearest available core, and core 26 is its hyperthread sibling. This configuration reduces overhead and latency for the PoH thread.

## System Tuning

The playbook performs comprehensive system tuning to optimize performance for the Solana validator:

### CPU Governor Configuration
- **CPU Governor Service**: Installs and enables a systemd service to ensure the CPU governor is set to performance mode.
- **Service Management**: The service is configured to start automatically and maintain the performance governor setting.

### File Limits Configuration
- **System File Limits**: Configures system-wide file limits to 1,000,000 open files.
- **Systemd Configuration**: Updates `/etc/systemd/system.conf` with appropriate file limit settings.
- **Security Limits**: Applies security limits configuration for the Solana user.

### System Parameters
- **Sysctl Tuning**: Updates various kernel parameters for optimal validator performance.
- **Daemon Reload**: Reloads the systemd daemon to apply all configuration changes.

> **Note:** These system tuning configurations are based on the [Anza documentation](https://docs.anza.xyz/operations/guides/validator-start#system-tuning)
>
> The numbered prefixes in configuration files (e.g., `21-agave-validator.conf`, `90-solana-nofiles.conf`) determine the order in which they are loaded. According to the [official sysctl.d(5) documentation](https://man7.org/linux/man-pages/man5/sysctl.d.5.html), "All configuration files are sorted by their filename in lexicographic order... It is recommended to prefix all filenames with a two-digit number and a dash to simplify the ordering." Lower numbers are loaded first, allowing higher-numbered files to override settings from lower-numbered files. This precedence system ensures that specific configurations can override general ones.
