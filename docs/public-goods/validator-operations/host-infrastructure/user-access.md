---
description: How to create and manage access for users on a new server
---

# User Access

Once your raw metal server is ready to host a Solana validator, the system administrator must provision access for the validator operators. This guide walks you through the process of running the Ansible script to provision users on a Solana Validator.

## Best Practices

By default, most ASN providers provision bare metal machines with the `ubuntu` user as the primary sudo user to manage the server.

Beyond `ubuntu` , our approach when it comes to security is that of lest privileges, where we define these identity and access management users and groups as follows:

<table><thead><tr><th width="206.796875">UBUNTU GROUPS</th><th width="278.9765625">DESCRIPTION</th><th>PERMISSION</th></tr></thead><tbody><tr><td>📂 sysadmin</td><td>Sudo access</td><td>To pre-set the permissions needed for each of the different roles played by operators.</td></tr><tr><td>📂 validator_admins</td><td>Can do everything to the validator, including install/uninstall, but nothing to the server</td><td><mark style="background-color:red;">????</mark></td></tr><tr><td>📂 validator_operators</td><td>Cannot install/uninstall the validator, but can perform all other operators, like upgrade, restart, migrate, start, and stop.</td><td><mark style="background-color:red;">????</mark></td></tr><tr><td>📂 validator_viewers</td><td>Can only view metrics, and run</td><td><mark style="background-color:red;">????</mark></td></tr><tr><td></td><td></td><td></td></tr></tbody></table>

{% hint style="warning" %}
These are the preset groups that will be provisioned AFTER running the user setup Ansible script. When configuring your iam\_setup.csv file ([see below](user-access.md#setup-users-csv)), make sure you use the correct group names on each user for their membership.
{% endhint %}

<table><thead><tr><th width="177.41796875">UBUNTU USERS</th><th width="294.82421875">DESCRIPTION</th><th>USAGE</th></tr></thead><tbody><tr><td>⚙️ <strong>ubuntu</strong></td><td>Provisioned by ASN with a server. Disabled after secure user setup.</td><td>To provision server users.</td></tr><tr><td>⚙️ <strong>sol</strong></td><td>Primary validator service runner and owner of the validator files and data.</td><td>Runs the validator service.</td></tr><tr><td>🧍Operator User:<br>>>> <strong>alice</strong>, <strong>bob</strong>, etc.</td><td>Each human operator has his/her dedicated Ubuntu user.</td><td>Access the server via SSH and run Ansible scripts from the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>.</td></tr></tbody></table>

## Prerequisites

Since the user provisioning is done via an Ansible script, you must have:

1. A running [Ansible Control](../../hayek-validator-kit/ansible-control.md)
2. Access to the user `ubuntu` on the provisioned server. See how [HERE](choosing-your-metal.md#provisioning).

## Setup Users CSV

The `pb_setup_server_users.yml` expects a CSV with users and groups meta that will be used for the identity and access management provisioning.

You can use the template below as a starting point and modify as needed. Once you are happy with the setup, put in your local workstation in a short and accessible path, like `~/Desktop` or `~/Setup`. You'll be using this path as a parameter when running the script.

{% file src="../../.gitbook/assets/iam_setup.csv" %}

## Executing the Playbook

Before running the playbook, ensure that your inventory file (`target_one_host.yml`) is updated with the IP address of the target server where you will install the users. Your inventory file should look like this:

```yaml
all:
  hosts:
    new-metal-box:
      ansible_host: 192.168.1.100
      ansible_port: 22
```

Replace `<target_ip_address>` with your actual values. Once the inventory is updated, you can run the playbook using:

```sh
ansible-playbook -i solana_new_metal_box.yml playbooks/pb_setup_server_users.yml \
  -e "target_host_name=new-metal-box" \
  -e "user_list=~/Desktop/iam_setup.csv"
```

{% hint style="danger" %}
**Note:** The playbook is configured to run with the user `ubuntu` which is the only user in the newly provisioned server.
{% endhint %}

## Confirmation Step

Upon running the playbook, you will see a confirmation asking you to verify the IP of the host you are about to change:

```
TASK [Show server IP and request confirmation] ******************************************************
[Show server IP and request confirmation]
IMPORTANT: You are about to run this playbook on the server with IP: 192.168.1.100

To continue, please type exactly this IP: 192.168.1.100

If you are not sure, press Ctrl+C to cancel.

Type IP here
```

This step is a safety measure to ensure you are provisioning the correct server. Type the IP address shown to continue. If you are not sure, press Ctrl+C to cancel the process.

## User Passwords

Only users who require sudo (elevated) privileges are provisioned with passwords. These passwords are securely generated and encrypted using the age tool with each user’s public key. Users with sudo access must decrypt their password locally using their private SSH key to perform privileged actions.

These users with elevated privileges [will receive an email](user-access.md#password-generation) with their temp password and should use [age tool](https://github.com/FiloSottile/age) like so:

* On Ubuntu/Debian: `apt install age`
* On macOS: `brew install age`

For all other users, no password is set. These users access the server exclusively via SSH key-based authentication, and cannot escalate privileges. This approach minimizes the attack surface while maintaining secure administrative access for authorized operators.

### Password Generation

<mark style="background-color:red;">The playbook will extract user information from the CSV file and generate a password for each user. These passwords will be encrypted using Ansible Vault and stored in a local directory on the operator's computer.</mark>

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
