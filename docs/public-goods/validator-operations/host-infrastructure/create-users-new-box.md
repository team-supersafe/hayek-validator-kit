---
description: Steps to create users on a newly provisioned server
---

# Create Users on a New Server

## Prerequisites

To follow these steps, make sure you have one of the following environments:

1. **Hayek .devcontainer**: This environment comes preconfigured with an `ansible-control` node and all necessary dependencies for management and automation.
2. **Visual Studio Code or Cursor Terminal**: Recommended for working with the devcontainer.
3. **Public SSH key configured on the provisioned server**: Ensure your public SSH key is added to the server you are provisioning. The steps to add your public key may vary depending on your hosting provider.
4. **age encryption tool installed**: This tool must be installed on each operator's workstation, as it will be used to decrypt the password, which will be encrypted using each user's public key. See the [official documentation](https://github.com/FiloSottile/age) for more details.
   - On Ubuntu/Debian: `apt install age`
   - On macOS: `brew install age`
5. **Create the secrets folder**: Create the folder `~/.new-metal-box-secrets` on your workstation. This folder must contain the file `users.csv`, which will hold all the information for the users to be created.

   **Example: users.csv**

   Below is an example of how the `users.csv` file should be structured (replace with your actual user data):

   | user   | email              | sent_email | key                                                                                  | group_a | group_b |
   |--------|--------------------|------------|-------------------------------------------------------------------------------------|---------|---------|
   | alice  | alice@example.com  | TRUE       | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyAlice alice@example.com              | Sol     | Sudo    |
   | bob    | bob@example.com    | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyBob bob@example.com                  | Sol     | Sudo    |
   | carol  | carol@example.com  | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyCarol carol@example.com              | Sol     | Sudo    |
   | dave   | dave@example.com   | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyDave dave@example.com                | Sol     | Sudo    |

   > **Note:**
   > This CSV solution was implemented to avoid publishing sensitive information in the configuration repository.
   > It is recommended to keep a copy of this file in a secure location where it can be downloaded when needed, such as 1Password, Keeper, or your preferred password manager. This file will **not** contain user passwords.

If you choose **not** to use the devcontainer, you must manually install the following dependencies on your system:

- Ansible
- Python
- passlib

You can install them on Debian/Ubuntu-based systems with the following command:

```sh
sudo apt update && sudo apt install -y ansible python3 python3-pip && pip3 install passlib
```

# User Creation Process

Once you have completed all prerequisites, follow these steps from the `ansible-control` node:

1. Change to the Ansible directory:
   ```sh
   cd ansible
   ```

## Relevant Ansible Structure

For the user creation process, you will only need the following files and directories from the `hayek-validator-kit/ansible` repository:

```
ansible/
├── playbooks/
│   └── pb_setup_server_users.yml
├── roles/
│   └── iam_manager/
│       ├── defaults/
│       │   └── main.yml
│       ├── files/
│       ├── tasks/
│       │   ├── backup_vault.yml
│       │   ├── cleanup.yml
│       │   ├── configure.yml
│       │   ├── create_passwords.yml
│       │   ├── create_users.yml
│       │   ├── disable_ubuntu.yml
│       │   ├── encrypt_passwords.yml
│       │   ├── main.yml
│       │   ├── precheck.yml
│       │   └── send_emails.yml
│       ├── templates/
│       │   ├── README.md
│       │   └── email_credentials.j2
│       └── vars/
│           └── main.yml
├── vault/
│   └── group_vars/
│       └── email_vars.yml
├── solana_new_metal_box.yml
```

### About `email_vars.yml`

The `email_vars.yml` file is encrypted with Ansible Vault because it contains the necessary variables to send access credentials to end users via email.

Below is an example of what this file might contain (replace with your actual SMTP configuration):

```yaml
# SMTP Server Configuration
smtp_host: smtp.example.com
smtp_port: 587
smtp_username: "admin@example.com"
smtp_password: "example-app-password"
smtp_from: "admin@example.com"
smtp_from_name: "System Administrator"
```

### Managing `email_vars.yml`

To view the contents of the encrypted `email_vars.yml` file, use:

```sh
ansible-vault view group_vars/all/email_vars.yml
```

To edit the file, use:

```sh
ansible-vault edit group_vars/all/email_vars.yml
```

### Variables in `ansible/roles/iam_manager/vars/main.yml`

The following variables are defined in the `ansible/roles/iam_manager/vars/main.yml` file:

```yaml
# CSV file containing user information (username, groups, email, etc.)
users_file: "~/.new-metal-box-secrets/users.csv"

# Vault file containing email-related variables and configurations
vault_file: "{{ inventory_dir }}/vault/group_vars/email_vars.yml"

# Directory for storing encrypted password backups with timestamps
encrypted_password_dir: "~/.encryptedpsw"
```

### Executing the Playbook

Before running the playbook, ensure that your inventory file (`solana_new_metal_box.yml`) is updated with the IP address of the target server where you will install the users.

For example, your inventory file should look something like this:

```yaml
all:
  hosts:
    # Host for provisioning new servers
    # Add to appropriate groups before running playbooks
    new-metal-box:
      ansible_host: 192.168.1.100
      ansible_port: 22
```

Replace `<target_ip_address>` with your actual values.

Once the inventory is updated, you can run the playbook using:

```sh
ansible-playbook -i solana_new_metal_box.yml playbooks/pb_setup_server_users.yml
```

**Note:** The playbook is configured to run with the user `ubuntu`. This is because providers like Vultr, Edgevana, and Latitude provision the server with the `ubuntu` user.

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

### Prechecks Executed by the Playbook

After confirming the IP, the playbook runs a series of prechecks to validate various aspects of the setup:

- **Validate CSV Structure**
  - Ensures the CSV file has the required fields (user, email, sent_email, key).
  - Fails if the CSV is empty or missing required fields.

- **Check for Existing Users**
  - Uses the `cut` command to get a list of existing users from `/etc/passwd`.
  - This is a security check to prevent overwriting existing users.

- **Fail if Users Exist**
  - Compares users from the CSV with existing system users.
  - If any users already exist, the playbook will fail for security reasons.

### Password Generation and Encryption

The playbook will extract user information from the CSV file and generate a password for each user. These passwords will be encrypted using Ansible Vault and stored in a local directory on the operator's computer.

During the execution, you will be prompted to enter a password to encrypt the vault file. This password is crucial as it will be needed later to view all the generated user credentials.

Ansible prompt:

```
Please enter a password to encrypt the vault file ~/.encryptedpsw/users_2025-06-17.yml
IMPORTANT: Save this password! You will need it later to view all the generated user credentials.
```

After entering the password, you will be asked to confirm it:

```
New Vault password:
Confirm New Vault password:
```

### Accessing Encrypted Passwords

After the passwords are encrypted and stored, the playbook will require access to this encrypted file to generate and encrypt individual password files for each user. These files will be sent to each user via email.

During the execution, you will be prompted to enter the password for the generated passwords vault file:

```
Please enter the password for the generated passwords vault file (/hayek-validator-kit/ansible/vault/group_vars/generated_pass.yml)
This password is needed to access the user passwords that were previously generated.
```

### User Creation and Group Assignment

The playbook will use the CSV file to create users. It will assign users to the corresponding groups based on the `group_a` and `group_b` columns. If either of these columns is empty, the playbook will omit the group assignment for that user.

### Public Key Configuration

Additionally, the playbook will extract the public keys for each user from the CSV file and configure them on the target server for each user.

### Temporary Password

The generated password is temporary. Users must change their password immediately upon accessing the server. This can be enforced using the command:

```sh
chage -d 0 {{ user }}
```
