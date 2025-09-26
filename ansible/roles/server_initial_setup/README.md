
# Server Initial Setup Role

> **Inventory Required:**
> Before running the playbook, edit your inventory file (e.g., `solana_new_metal_box.yml`) to set the correct IP and port for your target host:
>
> ```yaml
> all:
>   hosts:
>     new-metal-box:
>       ansible_host: 192.168.1.200  # Replace with your server's IP
>       ansible_port: 22
> ```

This role automates the initial configuration and hardening of a Solana validator server, including:
- System tuning
- Disk and mount setup
- SSH and firewall configuration
- Fail2ban setup
- Pre- and post-configuration checks

## Usage

1. **Prepare your inventory and variables:**
   - Define your target host in your inventory file.
   - Set the `ansible_user` and any other required variables.

2. **Prepare the authorized IPs CSV:**
   - Create a CSV file (e.g., `authorized_ips.csv`) with the following format:
     
     ```csv
     ip,comment
     203.0.113.1,Admin Office
     198.51.100.2,VPN Gateway
     192.0.2.10,Bastion Host
     203.0.113.5,Home Office
     ```
   - Do **not** use real IPs or sensitive names in your public documentation.

3. **Run the playbook:**
   

    ```sh
    ansible-playbook playbooks/pb_setup_metal_box.yml \
       -i solana_new_metal_box.yml \
       -e "target_host=new-metal-box" \
       -e "ansible_user=your-username" \
       -e "csv_file=authorized_ips.csv" \
       -K
    ```

    > **Note:** Before running the playbook, users with the `sysadmin` role must have previously logged in and provisioned a password using the Password Self-Service system. This is required for privilege escalation (`-K` flag).


   - The playbook will read the CSV and automatically create firewall rules to allow only the listed IPs to access the server's SSH port.


## Notes
- The CSV must have at least the columns: `ip` and `comment`.
- Only IPs listed in the CSV will be allowed through the firewall for SSH access.
- You can update the CSV and re-run the playbook to update access.

## Accessing the Server

After the playbook completes, you will need to access the server using the SSH port and user configured. Make sure to review the following variables:

- `ansible_user`: The username to use for SSH access.
- `firewall.ssh_port`: The SSH port (default: 2522, unless changed in your variables).
- Any password or SSH key requirements as provisioned by the sysadmin via Password Self-Service.


Refer to the role's `vars/main.yml` for all relevant configuration variables.

## After Playbook Completion

At the end of the playbook, the server will be rebooted automatically. You must reconnect using:

```sh
ssh validator@203.0.113.10 -p 2522
```

Replace the example values with your actual user, server IP, and port as configured.

---

For more details, see the role's tasks and variable files.
