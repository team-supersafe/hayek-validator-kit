---
description: How to create and manage access for users on a new server
---

# User Access

Once your raw metal server is ready to host a Solana validator, the system administrator must provision access for the validator operators. This guide walks you through the process of running the Ansible script to provision users on a newly provisioned metal server.

## Pre-Requisites

This page assumes you have access to a provisioned bare metal with the `ubuntu` user with `sudo` access as explained in the [Choosing Your Metal](choosing-your-metal.md) page.

Since the user provisioning is done via an Ansible script, you must also have a running [Ansible Control](../../hayek-validator-kit/ansible-control.md).

## Architecture

Our security strategy follows the principle of least privilege.

We define IAM users and roles in advance, which serve as the blueprint during setup. Each role maps directly to an Ubuntu group, ensuring every user operating on the host has only the minimal access required for their tasks.

### 🎭 Roles

These are the roles with their asserted purpose and description:

<table><thead><tr><th width="206.140625">ROLES (GROUPS)</th><th width="538.61328125">DESCRIPTION</th></tr></thead><tbody><tr><td>📂 <strong>sysadmin</strong><br><em>Purpose</em>: <br>Complete system administration</td><td>Sudo access. <br><br>Break-glass access for critical system emergencies</td></tr><tr><td>📂 <strong>validator_admins</strong><br><em>Purpose</em>: <br>Validator administration &#x26; development</td><td>Complete validator management without OS access. <br><br>Can do everything to the validator config either directly or via the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>, including install/uninstall, but nothing to the server or OS.</td></tr><tr><td>📂 <strong>validator_operators</strong><br><em>Purpose</em>: <br>Service operations &#x26; process control</td><td>Daily operational control without configuration capability.<br><br>Cannot install/uninstall the validator, but can perform other operations, like upgrade, restart, migrate, start, and stop either directly or via the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>.</td></tr><tr><td>📂 <strong>validator_viewers</strong><br><em>Purpose</em>: <br>System observability &#x26; metrics</td><td>Observability without modification capability.<br><br>This role is intended for users who need read-only access to the validator. Members can view service status, access logs, monitor, and inspect validator keys, but cannot perform any administrative or operational actions either directly or via the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>.</td></tr></tbody></table>

### 🚦 Permissions

These are the permissions that apply to each role along with some example commands that apply to each permission:

<table><thead><tr><th width="255.671875">PERMISSION</th><th>sysadmin</th><th>validator_admins</th><th>validator_operators</th><th>validator_viewers</th></tr></thead><tbody><tr><td><p><strong>user_mgmt</strong> <br><em>Example commands</em>: <code>sudo passwd forgetfuluser</code></p><p><code>sudo userdel baduser</code><br><code>sudo useradd gooduser</code></p></td><td>✅</td><td>❌</td><td>❌</td><td>❌</td></tr><tr><td><strong>pkg_mgmt</strong><br><em>Example commands</em>: <br><code>sudo apt update</code><br><code>sudo apt install htop</code><br></td><td>✅</td><td>✅</td><td>❌</td><td>❌</td></tr><tr><td><strong>pwd_selfsvc</strong><br><em>Example commands</em>: <br><code>sudo reset-my-password</code></td><td>✅</td><td>✅</td><td>❌</td><td>❌</td></tr><tr><td><strong>validator_mgmt</strong> <br><em>Example commands</em>: <br><code>sudo systemctl restart sol</code><br><code>kill UID sol service</code><br></td><td>✅</td><td>✅</td><td>✅</td><td>❌</td></tr><tr><td><p><strong>validator_monitoring</strong><br><em>Example commands</em>: <br><code>systemctl status sol</code></p><p><code>journalctl -u sol.service -f</code></p></td><td>✅</td><td>✅</td><td>✅</td><td>✅</td></tr></tbody></table>

### 👥 Users

Users belong to roles, except `ubuntu` and `sol`, which have special treatment as shown here:

<table><thead><tr><th width="168.9375">USERS</th><th width="281.00390625">DESCRIPTION</th><th>USAGE</th></tr></thead><tbody><tr><td>⚙️ <strong>ubuntu</strong></td><td>Provisioned by ASN with a server. Disabled after secure user setup.</td><td>To provision server users.</td></tr><tr><td>⚙️ <strong>sol</strong></td><td>Primary validator service runner and owner of the validator files and data.</td><td>Runs the validator service. Restricted to everything else.</td></tr><tr><td>🧍Operator User:<br>>>> <strong>alice</strong>, <strong>bob</strong>, etc.</td><td>Each human operator has his/her dedicated user.</td><td>Access the server via SSH, with no password.<br><br>Can run some Ansible scripts from the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a> depending on their role membership.</td></tr></tbody></table>

If a non-member user of a role, attempts to execute any of the commands within one of the permission, or attempts to run an Ansible Script with permissions they don't have, they will get an error that looks like this:

```bash
Sorry, user hugo is not allowed to execute '/usr/bin/apt udpate' as root on host-charlie.
```

Each role operates under the principle of least privilege with deny-by-default access control. Users are granted only the specific permissions explicitly defined using dedicated config files for each role. You can see the details later on this guide on under the [User Access](user-access.md#user-access) section.

## User Setup

### 🎛️ Config File

The `pb_setup_server_users.yml` expects a CSV with users and groups meta that will be used for the identity and access management provisioning.

You can use the template below as a starting point and modify as needed. Once you are happy with the setup, put in this folder  `~/new-metal-box/iam_setup.csv`. You'll be using this path as a parameter when running the script.

{% file src="../../.gitbook/assets/iam_setup.csv" %}

### ❇️ Provisioning

Before running the user provisioning playbook, ensure that your inventory file (`target_one_host.yml`) is updated with the IP address of the target server where you will install the users. Your inventory file should look like this:

```yaml
all:
  hosts:
    new-metal-box:
      ansible_host: 192.168.1.100
      ansible_port: 22
```

Replace `<target_ip_address>` with your actual values. Once the inventory is updated, you can run the playbook using:

```sh
ansible-playbook playbooks/pb_setup_server_users.yml \
  -i target_one_host.yml \
  -e "target_host=new-metal-box" \
  -e "ansible_user=ubuntu" \
  -e "csv_file=iam_setup.csv"
```

{% hint style="danger" %}
**Note:** The playbook is configured to run with the user `ubuntu` which is the only user in the newly provisioned server.
{% endhint %}

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

### ❌ Ubuntu User

Before the playbook completes, a **final security warning** is issued to inform the operator that the default `ubuntu` user will be disabled. This is a **deliberate security measure**, as many cloud providers (ASN) preconfigure servers with the `ubuntu` user by default, which poses a risk if left active.

A notification is displayed with the following message:

```bash
TASK [iam_manager : Notify about upcoming ubuntu user disablement] ******************************

MSG:

IMPORTANT WARNING: The ubuntu user will now be disabled.
After this task completes, you will LOSE CONNECTION to this server.
Please ensure you can connect with one of the newly created users:
- alan
- alice
- bob

TASK [iam_manager : Pause for warning] **********************************************************
[iam_manager : Pause for warning]
Press Enter to continue and disable ubuntu user (you will lose connection!), or Ctrl+C to abort:
```

{% hint style="danger" %}
Once confirmed, the `ubuntu` user is disabled, and the SSH session will be terminated.
{% endhint %}

### 🎟️ User Access

The playbook automatically configures the required sudo permissions for each role by deploying dedicated policy files under `/etc/sudoers.d/`. The system uses a hierarchical approach where higher roles inherit permissions from lower roles.

#### Role Hierarchy and Permissions

<table><thead><tr><th width="175.21484375">ROLE</th><th>FILE</th><th>INHERITANCE</th></tr></thead><tbody><tr><td><strong>sysadmin</strong></td><td><code>10-sysadmin</code></td><td>None (top level)</td></tr><tr><td><strong>validator_admins</strong></td><td><code>20-validator-admins</code></td><td>Inherits from operators</td></tr><tr><td><strong>validator_operators</strong></td><td><code>30-validator-operators</code></td><td>Inherits from viewers</td></tr><tr><td><strong>validator_viewers</strong></td><td><code>40-validator-viewers</code></td><td>Base level</td></tr></tbody></table>

## Password Self Service

Users who belong to the `sysadmin` or `validator_admins` groups are **required to set their own password** in order to perform privilege escalation via `sudo`.

### Initial Access

After the user logs in using their **SSH private key**, they will see a welcome message guiding them through the self-service password setup:

```bash
ssh -p 2522 alan@192.168.1.100
```

```
===============================================================================
                              WELCOME TO THE SYSTEM
===============================================================================
Welcome, alan!
===============================================================================

===============================================================================
                              PASSWORD MANAGEMENT
===============================================================================
To change your password, use: sudo reset-my-password

This command allows you to reset your password without entering your current
sudo password. It's a self-service feature for your convenience.
===============================================================================

```

Run the following command once logged in:

```bash
sudo reset-my-password
```

### Security Question Setup

After running the `sudo reset-my-password` command for the first time, users will be prompted to configure a **personal security question and answer**. This is a mandatory step in the password self-service process.

```bash
First-time setup: create your personal security question.
 Question (min 10 chars): secure question > 10 chars
 Answer (min 6 chars, will not echo): 
```

{% hint style="warning" %}
This security question and answer can be randomly generated using a password manager such as 1Password and securely stored in the same vault alongside your other credentials. It is important that the question is not something obvious or personal, as attackers may attempt to guess it using social engineering techniques. Treat your security question and answer with the same level of confidentiality as your password to ensure maximum protection.
{% endhint %}

The security question and answer are encrypted using **AES-256** with a high number of iterations and a unique salt, ensuring robust protection against brute-force or dictionary attacks. This encrypted data is stored in the path `/etc/password-security/alan`, with strict file permissions accessible **only by root**.

If a user wishes to reset their password using the self-service script (`sudo reset-my-password`), they will be prompted to correctly answer their security question.&#x20;

The user has **a maximum of 3 attempts**. After three failed answers, the script will deny further access for 24 hours, displaying the following message:

```bash
sudo reset-my-password
Security check: secure question > 10 chars...
 Answer: 
Incorrect answer. 2 attempts remaining.
 Answer: 
Incorrect answer. 1 attempts remaining.
 Answer: 
sdfsIncorrect answer. 0 attempts remaining.
Too many failed attempts. Account locked for 24 hours.
Contact administrator for immediate unlock.
```

To regain access before the lockout period ends, a **user from the `sysadmin` group** must either:

* Manually reset the password using `sudo passwd alan`, or
* **Remove the lock file** at `/etc/password-security/password-reset-blocked-alan` to re-enable the self-service flow.

### Password Self-Service Logging

To ensure full **traceability and auditability**, all user interactions with the `reset-my-password` script are logged in the file `/var/log/password-reset.log`. This includes events such as security question setup, password resets, and encryption actions.

Each log entry includes a timestamp, session ID, username, event type, and source IP address. This enables administrators to monitor and audit all password self-service activity in a secure and structured format.

```sh
[2025-07-23 03:51:09] [INFO] [SESSION:95939d91] [USER:alan] [TYPE:SESSION_START] [IP:172.25.0.10] Password reset process initiated  
[2025-07-23 03:51:09] [INFO] [SESSION:95939d91] [USER:alan] [TYPE:FIRST_TIME_SETUP] [IP:172.25.0.10] User creating initial security question  
[2025-07-23 03:55:59] [INFO] [SESSION:6298dffe] [USER:alan] [TYPE:QUESTION_CREATED] [IP:172.25.0.10] Security question created successfully  
[2025-07-23 04:04:31] [INFO] [SESSION:e56002e8] [USER:alan] [TYPE:ANSWER_CREATED] [IP:172.25.0.10] Security answer created successfully  
[2025-07-23 04:04:32] [INFO] [SESSION:e85a52ef] [USER:alan] [TYPE:QUESTION_ENCRYPTED] [IP:172.25.0.10] Security question encrypted with AES-256  
[2025-07-23 04:04:32] [INFO] [SESSION:e85a52ef] [USER:alan] [TYPE:SECURITY_QUESTION_SAVED] [IP:172.25.0.10] Security question and answer stored successfully  
```

All log files are owned by `root` and are protected from unauthorized access. This logging system ensures compliance with internal audit policies and helps detect misuse or suspicious activity in password operations.

## Discovering Your Sudo Permissions

To help users understand **what commands they are allowed to run**, a message is displayed at login as part of the system's **welcome screen**:

```
===============================================================================
                              WELCOME TO THE SYSTEM
===============================================================================
Welcome, alan!
===============================================================================

===============================================================================
                              USEFUL COMMANDS
===============================================================================
To check your current permissions, run:
  sudo -l -U alan

To view your permissions file:
  cat ~/permissions.txt
===============================================================================

```

Each user is provided with a `permissions.txt` file in their home directory. This file is:

* **Automatically generated** by Ansible during provisioning
* Updated based on the user’s **assigned role and sudoers configuration**

```bash
cat ~/permissions.txt
```

```
cat ~/permissions.txt

# REAL USER PERMISSIONS FOR alan
# ================================================
# This file shows the REAL permissions you have on this server
# based on your current sudoers configuration
#
# Automatically generated by Ansible
# Last updated: 2025-07-23T02:47:16Z

systemctl status sol.service
journalctl -u sol.service --no-pager
tail -f /home/sol/logs/agave-validator.log
tail -n 50 /home/sol/logs/agave-validator.log
pgrep -f sol.service
du -sh /mnt/ledger
du -sh /mnt/accounts
```

