## Requirements: CSV Files for Users/Roles and Authorized IPs

For testing, you will need two CSV files:

- A CSV containing the users and their roles
- A CSV containing the IPs authorized to connect to the server

These CSVs should be placed in your **local computer**:

   ~/new-metal-box/


### Example: Users and Roles CSV (`~/new-metal-box/iam_setup_dev.csv`)

> **Testing Tip:** For testing purposes only, it is recommended to use the same public key for all users in the CSV. This allows you to access the server as each user and verify their roles and permissions work as expected. Use a public key you have access to.

```
user,key,group_a,group_b,group_c
alice,ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeyforalice alice@example.com,sysadmin,,
bob,ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeyforbob bob@example.com,,validator_operators,
carla,ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEexamplekeyforcarla carla@example.com,validator_viewers,,
```

### Example: Authorized IPs CSV (`~/new-metal-box/authorized_ips.csv`)

```
ip,comment
203.0.113.1,Admin Office
198.51.100.2,VPN Gateway
192.0.2.10,Bastion Host
203.0.113.5,Home Office
```

## Getting Started: Acquire Bare Metal

The first step is to acquire a bare metal server. It is recommended to use Latitude as a provider for best compatibility.

You can follow the necessary documentation here:
https://docs.hayek.fi/dev-public-goods/validator-operations/host-infrastructure/choosing-your-metal#latitude-complete-provisioning

**For testing, you can use the m4.metal.medium server**


## Post-Provisioning Verifications

Once you have selected the necessary server for your tests, you should run a quick check to ensure the server meets the minimum requirements. You can follow this documentation:
https://docs.hayek.fi/dev-public-goods/validator-operations/host-infrastructure/choosing-your-metal#post-provisioning-verifications


## Update Inventory

**Inventory Required:**
 Before running the playbooks, edit your inventory file (`solana_new_metal_box.yml`) to set the correct IP and port for your target host:

 ```yaml
 all:
   hosts:
     new-metal-box:
       ansible_host: 192.168.1.200  # Replace with your server's IP
       ansible_port: 22
 ```


## User and Role Setup

After updating your inventory with the IP of the server to be provisioned and verifying that the server meets the minimum requirements (no RAID enabled and SMT is active), you need to create the users and roles using the playbook `pb_setup_server_users.yml`.


To execute this playbook, follow the documentation here:
https://docs.hayek.fi/dev-public-goods/validator-operations/host-infrastructure/user-access#user-setup

Once the users have been created on the server, to continue with the setup and testing, you must access the server with a user that belongs to the sysadmin group and provision a password using the Password Self-Service system. 
See the documentation here:
https://docs.hayek.fi/dev-public-goods/validator-operations/host-infrastructure/user-access#password-self-service



## Server Configuration and Hardening

At this point, the server is ready to be configured.

This role automates the initial configuration and hardening of a Solana validator server, including:
- System tuning
- Disk and mount setup
- SSH and firewall configuration
- Fail2ban setup
- Pre- and post-configuration checks

## Running the Playbook

1. **Prepare the authorized IPs CSV:**
   - Ensure you have the authorized IPs CSV as described in the [Requirements](#requirements-csv-files-for-usersroles-and-authorized-ips) section at the top of this documentation.
   - Do **not** use real IPs or sensitive names in your public documentation.

2. **Run the playbook:**
   
 ```sh
ansible-playbook playbooks/pb_setup_metal_box.yml \
   -i solana_new_metal_box.yml \
   -e "target_host=new-metal-box" \
   -e "ansible_user=alice" \
   -e "csv_file=authorized_ips.csv" \
   -K
```

> **Note:** Before running the playbook, users with the `sysadmin` role must have previously logged in and provisioned a password using the Password Self-Service system. This is required for privilege escalation (`-K` flag).




Upon running the playbook, you will see a confirmation asking you to verify the IP of the host you are about to change:

```
TASK [Show server IP and location for confirmation] ******************************
[Show server IP and location for confirmation]
IMPORTANT: You are about to run this playbook on the server with IP: 192.168.1.100

Location Information:
- City: Unknown
- Country: Unknown
- Organization: Unknown

To continue, please type exactly this IP: 192.168.1.100

If you are not sure, press Ctrl+C to cancel.

Type IP here
```
This step is a safety measure to ensure you are provisioning the correct server. Type the IP address shown to continue. If you are not sure, press Ctrl+C to cancel the process.


## Server Restart Prompt

At the end of the playbook, you will be prompted with:
```bash
   Do you want to restart the server now? (y/n)

   Skipping the restart means some optimizations (such as CPU isolation and kernel tuning) will not be active until the next reboot.
```
## After Playbook Completion

At the end of the playbook, the server will be rebooted automatically. You must reconnect using:

```sh
ssh alice@203.0.113.10 -p 2522
```

Replace the example values with your actual user, server IP, and port as configured.

Note: If your user belongs to the `validator_operators` or `sysadmin` group, you will be able to use the Password Self-Service by following the instructions on the welcome screen after logging in.

To verify that the server has the optimal configuration for a Solana validator, you can use the health_check script:

```sh
   bash /opt/validator/scripts/health_check.sh 
```
---

