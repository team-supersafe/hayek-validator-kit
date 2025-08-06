---
description: >-
  Testing security and host infrastructure and provisioning in automated ways to
  ensure indempotency when making changes
---

# Infra Testing

The testing suite validates:

* **RBAC (Role-Based Access Control)**: Ensures proper user permissions and group access rights
* **Service Management**: Tests Unix service creation, deployment, and monitoring capabilities
* **System Integration**: Verifies that all components work together correctly in the validator environment
* **Development Guide**: Serves as a reference guide for developing new playbooks that integrate with RBAC

### Prerequisites

#### Infrastructure Requirements

* Clear VPS/Docker container or VM that you can use to run the tests
* Network access to the target server
* SSH connectivity configured
* A running [Ansible Control](../../hayek-validator-kit/ansible-control.md)

#### User Provisioning

* [User provisioning playbook executed ](user-access.md#executing-the-playbook)on the target server
* Users and groups created according to [RBAC](user-access.md#best-practices) requirements

#### Multi-User Testing (Optional)

If you want to run tests for all users, you need:

* [CSV](user-access.md#setup-users-csv) file modified (for testing purposes only)
* Public key added for each user in the [CSV](user-access.md#setup-users-csv)

{% hint style="danger" %}
**UNDER NO CIRCUMSTANCES execute these tests on production servers.** \
**USE ONLY DEVELOPMENT ENVIRONMENTS.**\
These tests are designed for development and testing environments, staging servers, isolated testing environments, Docker containers or VMs for testing purposes.
{% endhint %}

### Available Playbooks

#### pb\_test\_rbac.yml

This playbook performs comprehensive Role-Based Access Control (RBAC) testing to validate user permissions and group access rights. It tests various system commands including logrotate management, cron operations, package management with apt-get, and system monitoring capabilities. The playbook verifies that users have the correct permissions based on their assigned groups (sysadmin, validator\_admins, validator\_operators) and provides detailed output showing which operations succeed or fail for each user type. The tasks were conceived based on the permissions that were predefined as examples in the [User Access](user-access.md#best-practices) documentation table.\


**Example**: If a user belonging to the **validator\_operator** role executes `sudo apt-get update` and this task succeeds, the RBAC is expected to fail since this role is defined to not have access to execute this command within the server.

#### pb\_test\_build.yml

This playbook tests the build and compilation capabilities within the validator environment. It validates that users can perform build operations, compile software components, and manage development tools according to their assigned permissions. The playbook ensures that build processes work correctly while respecting RBAC restrictions and provides feedback on build success or failure based on user privileges.

#### pb\_test\_setup\_service.yml

This playbook tests the creation and management of Unix services within the validator infrastructure. It validates the ability to create systemd services, configure service parameters, and manage service lifecycle operations. The playbook tests service deployment capabilities while ensuring proper user permissions and provides comprehensive feedback on service creation, configuration, and operational status.

### Executing RBAC Tests

Once the target has been configured with users and their roles defined, we can start executing the tests.

#### Basic Execution

User details

* **Usuario**: hugo
* **Role**: validator\_viewers

We will evaluate hugo's permissions to verify that the RBAC system correctly restricts access based on the validator\_viewers role.

Navigate to tests directory

```bash
cd ansible/tests
```

Before running the playbook, ensure that your inventory file is updated with the IP address of the target server where you will install the users. Your inventory file should look like this:

```yaml
all:
  hosts:
    host-charlie:
      ansible_host: 198.168.1.100
      ansible_port: 22
```

Run RBAC tests

```bash
ansible-playbook playbooks/pb_test_rbac.yml \
  -e "target_host=host-charlie" \
  -e "ansible_user=hugo"
```

#### Confirmation Step

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

#### Test Execution Behavior

Once the IP address is confirmed, a series of evaluation tasks will be executed immediately. Some of these tasks will fail if the user being evaluated cannot execute them. In this case, **a failure is good news** as it indicates that RBAC is working correctly.

Example of Expected Failure

```
TASK [test_rbac : Test sudo permissions for apt-get update] ***********************
fatal: [host-charlie]: FAILED! => {
    "changed": true,
    "cmd": "timeout 30 sudo -n apt-get update",
    "delta": "0:00:01.006040",
    "end": "2025-08-05 23:26:35.558051",
    "rc": 1,
    "start": "2025-08-05 23:26:34.552011"
}

STDERR:
sudo: a password is required
MSG:
non-zero return code
...ignoring
```

This failure indicates that hugo could not execute `sudo apt update,` which is exactly what is defined by his role - he should not be able to perform this operation. This is a **successful RBAC validation**.



Example of Successful Task

```
TASK [test_rbac : Display free -h result] **************************
ok: [host-charlie] => {}

MSG:

User hugo - Attempt to run free -h: SUCCESS

```

This success indicates that hugo, as his role is primarily for monitoring, can execute `free -h` and check available memory, which is appropriate for his validator\_viewers role.

#### Display RBAC Test Summary

### Interpreting Final Results

| Test User     | hugo                     |
| ------------- | ------------------------ |
| User Groups   | hugo: validator\_viewers |
| Detected Role | validator\_viewer        |

| PERMISSION TEST RESULTS  | Status  |
| ------------------------ | ------- |
| systemctl stop logrotate | FAILED  |
| sudo systemctl stop cron | FAILED  |
| sudo apt-get update      | FAILED  |
| sudo apt-get install     | FAILED  |
| free -h                  | SUCCESS |

| EXPECTED PERMISSIONS (validator\_viewer) | Status  |
| ---------------------------------------- | ------- |
| systemctl stop logrotate                 | FAILED  |
| sudo systemctl stop cron                 | FAILED  |
| sudo apt-get update                      | FAILED  |
| sudo apt-get install                     | FAILED  |
| free -h                                  | SUCCESS |

| COMPLIANCE CHECK       | Status  |
| ---------------------- | ------- |
| Logrotate permission   | CORRECT |
| Cron permission        | CORRECT |
| Apt update permission  | CORRECT |
| Apt install permission | CORRECT |
| Free -h permission     | CORRECT |

The RBAC test results demonstrate perfect compliance with the validator\_viewer role. User hugo correctly failed all administrative operations while successfully executing monitoring commands, confirming that the role-based access control system is functioning exactly as designed.

At the end, we summarize the result for hugo. If he failed the restricted tasks and only executed the permitted ones, the result will be **PASS**.

```
TASK [test_rbac : Display Final Summary] *************************
ok: [host-charlie] => {}

MSG:

========================================
FINAL SUMMARY
========================================
User: hugo
Role: validator_viewer
Groups: hugo : hugo validator_viewers
RBAC Compliance: PASS
========================================
```

#### User-by-User Evaluation

To properly evaluate RBAC, you need to test each user individually based on their role within the server. This requires executing the playbook for each user separately.

#### Why Individual User Testing is Required

Due to the server's own configuration, evaluation must be done per user because when establishing an SSH connection with a user like hugo, they cannot perform `become_user:` operations, as this is something only a user with sudo privileges can do.

#### For each user you want to evaluate:

```bash
ansible-playbook playbooks/pb_test_rbac.yml \
  -e "target_host=host-charlie" \
  -e "ansible_user=bob"
```

#### Evaluating sysadmin

Remember that users belonging to the sysadmin group can execute any task within the target. However, if you want to evaluate these users as well, you can do so since the playbook is prepared for this. Just keep in mind that first you must access the server with the user and create a password using the password self-service script (more details in [User Access ](user-access.md#password-self-service)documentation). Once you have the password, execute the playbook adding `-K` to elevate permissions as sysadmin.

```bash
ansible-playbook playbooks/pb_test_rbac.yml \
  -e "target_host=host-charlie" \
  -e "ansible_user=username" \
  -K
```

Type the password where you created it before.

### Executing BUILD Test

For a UNIX test of how the RBAC mechanism adapts to the installation of a compiled application, a test scenario was created where a user compiles the HTOP app from source.

#### Requirements for Successful Execution

For a user to execute this Playbook successfully, they must meet the following requirements:

1. Belong to the `ansible_executor` role - This group has certain permissions required by Ansible to execute tasks using its modules and not through shell
2. Belong to the `validator_admins` role - This is the group with the necessary permissions (rwx) in the `/home/sol` folder
3. Users belonging to the `ansible_executor` role must first [self-provision](user-access.md#password-self-service) a password.

#### Basic Execution

User details

* **Usuario**: bob
* **Role**: validator\_admins, ansible\_executor

Navigate to tests directory

```bash
cd ansible/tests
```

Run BUILD Test

```bash
ansible-playbook playbooks/pb_test_build.yml \
  -e "target_host=host-charlie" \
  -e "htop_version=3.3.0" \
  -e "ansible_user=bob" \
  -K
```

Type the password where you created it before.

#### Confirmation Step

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

Type the IP address shown to continue. If you are not sure, press Ctrl+C to cancel the process.

#### Expected Result

Once the playbook is executed, the download and compilation process of the htop package will begin quickly. Upon completion, if everything goes well, you should obtain this result:

```
TASK [test_build : Display result] ******************************
ok: [host-charlie] => {}

MSG:

htop 3.3.0 installed successfully:
- User installation: /home/sol/.local/bin/htop
- System-wide link: /usr/local/bin/htop
- Symlink test: SUCCESS
```

Now HTOP is available for any user. You can test by executing `htop -V` to verify the installation.

### Executing provicion a service

This playbook is responsible for configuring, enabling, and running a test service on the server. This service will run as the user `sol` and will execute a script located in `/home/sol/unix-test.sh`, which writes a log to a file every 30 seconds.

#### Objective

The goal is to have a reference when creating a task that is responsible for configuring services. This provides a template for service deployment and management within the RBAC framework.

#### Requirements for Successful Execution

For a user to execute this Playbook successfully, they must meet the following requirements:

1. Belong to the `ansible_executor` role - This group has certain permissions required by Ansible to execute tasks using its modules and not through shell
2. Belong to the `validator_admins` role - This is the group with the necessary permissions (rwx) in the `/home/sol` folder
3. Users belonging to the `ansible_executor` role must first [self-provision](user-access.md#password-self-service) a password.

#### Basic Execution

User details

* **Usuario**: bob
* **Role**: validator\_admins, ansible\_executor

Navigate to tests directory

```bash
cd ansible/tests
```

Run BUILD Test

```bash
aansible-playbook playbooks/pb_test_setup_service.yml \
  -e "target_host=host-charlie" \
  -e "ansible_user=bob" \
  -K
```

Type the password where you created it before.

#### Confirmation Step

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

Type the IP address shown to continue. If you are not sure, press Ctrl+C to cancel the process.

#### Expected Result

Once the playbook is executed, the provisioning of this service will begin. Upon completion, you can verify if the execution was successful:

```
TASK [test_service_creation : Display service summary] ********************
ok: [host-charlie] => {}
MSG:
========================================
UNIX TEST SERVICE SUMMARY
========================================
Service Name: unix-test-service
Service Status: active
Service PID: 12172
Process User: sol

Status File: /tmp/unix-test-status.txt
File Exists: true
File Content: Unix Testing in Progress - Wed Aug  6 01:02:46 UTC 2025

Last Modified: Wed Aug  6 01:02:46 UTC 2025

Service Logs:
Aug 05 18:29:40 host-charlie systemd[1]: Started unix-test-service.service - Unix Test Service.
========================================
```

Manual Validation

If you prefer, you can access the server and execute some commands to validate this:

```bash
# Check service status
systemctl status unix-test-service.service

# View systemd logs
journalctl -u unix-test-service.service -f
```
