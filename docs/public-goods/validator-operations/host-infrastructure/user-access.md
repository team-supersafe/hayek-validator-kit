---
description: How to create and manage access for users on a new server
---

# User Access

Once your raw metal server is ready to host a Solana validator, the system administrator must provision access for the validator operators. This guide walks you through the process of running the Ansible script to provision users on a newly provisioned metal server.

## Pre-Requisites

This page assumes you have access to a provisioned bare metal with the `ubuntu` user with `sudo` access as explained in the [Choosing Your Metal](choosing-your-metal.md) page.

Since the user provisioning is done via an Ansible script, you must also have a running [Ansible Control](../../hayek-validator-kit/ansible-control.md).

## Least Privilege & RBAC

Our security strategy is based on the principle of least privilege.&#x20;

First, we define our identity and access management (IAM) users and groups, which will serve as the guide during the setup. These groups ensure dedicated minimum access to the different users that will be acting on our host:

<table><thead><tr><th>RBAC (UBUNTU GROUPS)</th><th width="538.61328125">DESCRIPTION</th></tr></thead><tbody><tr><td>📂 sysadmin</td><td>Sudo access</td></tr><tr><td>📂 validator_admins</td><td>Can do everything to the validator, including install/uninstall, but nothing to the server</td></tr><tr><td>📂 validator_operators</td><td>Cannot install/uninstall the validator, but can perform all other operators, like upgrade, restart, migrate, start, and stop.</td></tr><tr><td>📂 ansible_executor</td><td>The <code>ansible_executor</code> role is assigned to users who need permission to run Ansible playbooks. Users with this role must be members of the <code>ansible_executor</code> group and are required to configure their own password using the self-service password setup. This ensures secure privilege escalation and auditability while maintaining least-privilege access.</td></tr><tr><td>📂 validator_viewers</td><td>The <code>validator_viewers</code> role is intended for users who need read-only access to validator-related operations. Members of this role can view service statuses, access logs, monitoring and inspect validator keys, but cannot perform any administrative or write actions.</td></tr><tr><td></td><td></td></tr></tbody></table>

Each Role/Group operates under the principle of least privilege with deny-by-default access control. Users are granted only the specific permissions explicitly defined in the following table, with higher-level roles inheriting permissions from lower-level roles through template-based inheritance:



| ROLE                 | SCOPE                                  | PERMISSION\_MODEL               | FUNCTIONAL\_AREAS                                                                                                                                         | ROLE\_PURPOSE                                              |
| -------------------- | -------------------------------------- | ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| sysadmin             | Complete system administration         | <p>Privileged<br>PRIVILEGED</p> | <p>System_Administration<br>User_Management<br>Password_Self_Service</p>                                                                                  | Break-glass access for critical system emergencies         |
| validator\_admins    | Validator administration & development | ADMINISTRATIVE                  | <p>Software_Management Service_Configuration Development_Tools<br>Key_Management:  Configuration_Management: [chmod, chown, cp, mv on validator dirs]</p> | Complete validator management without OS access            |
| validator\_operators | Service operations & process control   | OPERATIONAL\_CONTROL            | <p>Solana_Service_Control<br>Solana_Process_Management<br>Operational_Monitoring</p>                                                                      | Daily operational control without configuration capability |
| validator\_viewers   | System observability & metrics         | READ\_ONLY MONITORING           | <p>Status_Monitoring Solana_Log_Analysis<br>Network_Monitorin<br>Performance_Monitoring<br>Validator_Configuration_Viewing</p>                            | Observability without modification capability              |
| ansible\_executor    | Automated deployment execution         | PROGRAMMATIC\_LIMITED           | <p>Shell_Access<br>Password_Self_Service</p>                                                                                                              | Non-interactive user for automation only                   |



#### PERMISSION VALIDATION MATRIX

| COMMAND                    | sysadmin | validator\_admins | validator\_operators | validator\_viewers |
| -------------------------- | -------- | ----------------- | -------------------- | ------------------ |
| sudo useradd newoperator   | ✅        | ❌                 | ❌                    | ❌                  |
| sudo reset-my-password     | ✅        | ❌                 | ❌                    | ❌                  |
| sudo apt-get install htop  | ✅        | ✅                 | ❌                    | ❌                  |
| sudo systemctl restart sol | ✅        | ✅                 | ✅                    | ❌                  |
| systemctl status sol       | ✅        | ✅                 | ✅                    | ✅                  |

<table><thead><tr><th width="177.41796875">USERS</th><th width="294.82421875">DESCRIPTION</th><th>USAGE</th></tr></thead><tbody><tr><td>⚙️ <strong>ubuntu</strong></td><td>Provisioned by ASN with a server. Disabled after secure user setup.</td><td>To provision server users.</td></tr><tr><td>⚙️ <strong>sol</strong></td><td>Primary validator service runner and owner of the validator files and data.</td><td>Runs the validator service.</td></tr><tr><td>🧍Operator User:<br>>>> <strong>alice</strong>, <strong>bob</strong>, etc.</td><td>Each human operator has his/her dedicated user.</td><td>Access the server via SSH and run Ansible scripts from the <a href="../../hayek-validator-kit/ansible-control.md">Ansible Control</a>.</td></tr></tbody></table>

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

<table><thead><tr><th width="175.21484375">ROLE</th><th>FILE</th><th>INHERITANCE</th></tr></thead><tbody><tr><td><strong>sysadmin</strong></td><td><code>10-sysadmin</code></td><td>None (top level)</td></tr><tr><td><strong>validator_admins</strong></td><td><code>20-validator-admins</code></td><td>Inherits from operators</td></tr><tr><td><strong>validator_operators</strong></td><td><code>30-validator-operators</code></td><td>Inherits from viewers</td></tr><tr><td><strong>validator_viewers</strong></td><td><code>40-validator-viewers</code></td><td>Base level</td></tr><tr><td><strong>ansible_executor</strong></td><td><code>40-ansible-executor</code></td><td>Special purpose</td></tr></tbody></table>

## Password Self Service

Users who belong to the `sysadmin` or `ansible_executor` groups are **required to set their own password** in order to perform privilege escalation via `sudo`.

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

