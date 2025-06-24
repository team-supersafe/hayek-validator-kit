---
description: How to create and manage access for users on a new server
---

# User Access

Once your raw metal server is ready to host a Solana validator, the system administrator must provision access for the validator operators. This guide walks you through the process of running the Ansible script to provision users on a Solana Validator.

## Best Practices

By default, most ASN providers provision bare metal machines with the `ubuntu` user as the primary sudo user to manage the server.

Beyond `ubuntu` , our approach when it comes to security is that of lest privileges, where we define these identity and access management users and groups:

<table><thead><tr><th width="177.41796875">User / Group</th><th width="294.82421875">Description</th><th>Usage</th></tr></thead><tbody><tr><td>⚙️ <strong>ubuntu</strong></td><td>Provisioned by ASN with a server. Disabled after secure user setup.</td><td>To provision server users.</td></tr><tr><td>⚙️ <strong>sol</strong></td><td>Primary validator service runner and owner of the validator files and data.</td><td>Runs the validator service.</td></tr><tr><td>🧍Operator User:<br>>>> <strong>alice</strong>, <strong>bob</strong>, etc.</td><td>Each human operator has his/her dedicated Ubuntu user.</td><td>Access the server via SSH and run Ansible scripts from the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>.</td></tr><tr><td><p>📂 Role Groups:<br>>>> <strong>val_admin</strong>, </p><p><strong>val_operator, val_viewer</strong>, etc.</p></td><td>Ubuntu Groups with specific validator permissions for each type of user, like Validator Logs/Metrics Viewer, Validator Operators, and Validator Administrators.</td><td>To pre-set the permissions needed for each of the different roles played by operators.</td></tr><tr><td><mark style="background-color:orange;">Alt to Role Groups</mark>:<br>---------------------<br>📂 Playbook Group:<br>>>> <strong>grp_pb_one</strong>, <strong>grp_pb_two</strong>, etc.</td><td>Ubuntu Groups with specific permissions for each playbook that can be run on this server.</td><td>To limit the participation of operator users per playbook groups.</td></tr></tbody></table>









## Prerequisites

Since the user provisioning is done via an Ansible script, you must have:

1. A running [Ansible Control](../../hayek-validator-kit/ansible-control.md)
2. Access to the user `ubuntu` on the provisioned server. See how [HERE](choosing-your-metal.md#provisioning).















To follow these steps, make sure you have **one of** the following environments:&#x20;

1.
2. **age encryption tool installed**: This tool must be installed on each operator's workstation, as it will be used to decrypt the password, which will be encrypted using each user's public key. See the [official documentation](https://github.com/FiloSottile/age) for more details.
   * On Ubuntu/Debian: `apt install age`
   * On macOS: `brew install age`
3.  **Create the secrets folder**: Create the folder `~/.new-metal-box-secrets` on your workstation. This folder must contain the file `users.csv`, which will hold all the information for the users to be created.

    **Example: users.csv**

    Below is an example of how the `users.csv` file should be structured (replace with your actual user data):

    | user  | email             | sent\_email | key                                                                    | group\_a | group\_b |
    | ----- | ----------------- | ----------- | ---------------------------------------------------------------------- | -------- | -------- |
    | alice | alice@example.com | TRUE        | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyAlice alice@example.com | Sol      | Sudo     |
    | bob   | bob@example.com   | FALSE       | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyBob bob@example.com     | Sol      | Sudo     |
    | carol | carol@example.com | FALSE       | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyCarol carol@example.com | Sol      | Sudo     |
    | dave  | dave@example.com  | FALSE       | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyDave dave@example.com   | Sol      | Sudo     |

    > **Note:**\
    > This CSV solution was implemented to avoid publishing sensitive information in the configuration repository.\
    > It is recommended to keep a copy of this file in a secure location where it can be downloaded when needed, such as 1Password, Keeper, or your preferred password manager. This file will **not** contain user passwords.

If you choose **not** to use the devcontainer, you must manually install the following dependencies on your system:

* Ansible
* Python
* passlib

You can install them on Debian/Ubuntu-based systems with the following command:

```sh
sudo apt update && sudo apt install -y ansible python3 python3-pip && pip3 install passlib
```

## Creating users

Once you have completed all prerequisites, follow these steps from the `ansible-control` node:

1.  Change to the Ansible directory:

    ```sh
    cd ansible
    ```

### Relevant Ansible Structure

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

### Configuration Variables

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

* Type the IP address shown to continue.
* If you are not sure, press Ctrl+C to cancel the process.

### Prechecks Executed by the Playbook

After confirming the IP, the playbook runs a series of prechecks to validate various aspects of the setup:

* **Validate CSV Structure**
  * Ensures the CSV file has the required fields (user, email, sent\_email, key).
  * Fails if the CSV is empty or missing required fields.
* **Check for Existing Users**
  * Uses the `cut` command to get a list of existing users from `/etc/passwd`.
  * This is a security check to prevent overwriting existing users.
* **Fail if Users Exist**
  * Compares users from the CSV with existing system users.
  * If any users already exist, the playbook will fail for security reasons.

#### Password Generation and Encryption

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

#### Accessing Encrypted Passwords

After the passwords are encrypted and stored, the playbook will require access to this encrypted file to generate and encrypt individual password files for each user. These files will be sent to each user via email.

During the execution, you will be prompted to enter the password for the generated passwords vault file:

```
Please enter the password for the generated passwords vault file (/hayek-validator-kit/ansible/vault/group_vars/generated_pass.yml)
This password is needed to access the user passwords that were previously generated.
```

#### User Creation and Group Assignment

The playbook will use the CSV file to create users. It will assign users to the corresponding groups based on the `group_a` and `group_b` columns. If either of these columns is empty, the playbook will omit the group assignment for that user.

#### Public Key Configuration

Additionally, the playbook will extract the public keys for each user from the CSV file and configure them on the target server for each user.

#### Temporary Password

The generated password is temporary. Users must change their password immediately upon accessing the server. This can be enforced using the command:

```sh
chage -d 0 {{ user }}
```

#### Sending Encrypted Passwords via Email

To send the passwords via email, the playbook needs access to the encrypted file containing the SMTP configurations, `email_vars.yml`. The passwords are encrypted using the `age` tool with each user's public key, which must be included in the CSV.

Below is an example of the email sent to users:

```
Hello dave,

Your server access credentials have been encrypted with your SSH public key.
For decrypt the password, you need to have the private key of the user.

Server IP: 192.168.1.100
Username: dave

The encrypted password file is attached to this email.

To decrypt your password:
1. Install age if not already installed:
   - On Ubuntu/Debian: apt install age
   - On macOS: brew install age
2. Save the attachment and run:
   age -d -i ~/.ssh/private_key dave_password.age

Connection command:
ssh -p 2522 dave@192.168.1.100

Please change your password upon first login.

Best regards,
System Administrator
```

#### Cleanup

The playbook includes cleanup tasks to ensure that temporary vault files are removed after use. This is done to prevent potential issues with leftover files. The following tasks are executed:

* **Delete temporal vault file if it exists**: This task removes the temporary vault file specified by `generated_pass_file` to avoid any issues with leftover files.
* **Delete temporal vault file backup if it exists**: This task removes any backup of the temporary vault file, ensuring that no sensitive information is left behind.

These tasks are delegated to the localhost to ensure they are executed on the control machine.

#### Disabling the Ubuntu User

The playbook includes tasks to disable the `ubuntu` user after the new users are created. This is a security measure to prevent unauthorized access. The following tasks are executed:

* **Disable ubuntu user**: This task disables the `ubuntu` user by locking the password and changing the shell to `/usr/sbin/nologin`.
* **Block SSH login for ubuntu user**: This task modifies the SSH configuration to deny login for the `ubuntu` user.
* **Restart SSH service**: This task restarts the SSH service to apply the changes.

These tasks ensure that the `ubuntu` user is completely disabled, and you must use one of the newly created users to access the server.
