# Strategy Proposal: Solana Validator RBAC (Role-Based Access Control) Documentation

## Table of Contents
1. [Overview](#overview)
2. [RBAC Roles and Permissions](#rbac-roles-and-permissions)
3. [Multi-User Server Management](#multi-user-server-management)
4. [Implementation Strategy](#implementation-strategy)
5. [Ansible Playbook Integration](#ansible-playbook-integration)
6. [Security Best Practices](#security-best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Overview

This document describes the Role-Based Access Control (RBAC) system for Solana validator management. The system implements four distinct roles with specific permissions to ensure secure and controlled access to validator operations.

### Key Principles
- **Principle of Least Privilege**: Users have only the minimum permissions necessary for their tasks
- **Role-Based Access**: Access is granted based on user roles rather than individual permissions
- **Separation of Duties**: Different roles handle different aspects of validator management
- **Audit Trail**: All actions are logged for security and compliance

### Sol User
- **sol user**: Dedicated user for running the Solana validator service
- **Service Owner**: Owns and runs the `sol.service` systemd service
- **Storage Owner**: Owns the validator storage directories (`/mnt/ledger`, `/mnt/accounts`, `/mnt/snapshots`)

---

## RBAC Roles and Permissions

### 1. 🔧 sysadmin
**Description**: Full system access with sudo privileges

#### System Permissions:
- **Full sudo access**: `ALL=(ALL) ALL` (password required for elevation)
- **User management**: Create, modify, delete users and groups
- **Package management**: `apt-get`, `snap`, `dpkg`, `apt`
- **Service management**: All system services
- **File system access**: Complete access to entire system
- **Network configuration**: Firewall, interfaces, routing
- **Disk management**: Partitioning, formatting, mounting
- **Log management**: Access to all system logs
- **Process management**: Kill, renice, process monitoring
- **Cron management**: System-wide cron jobs
- **Security configuration**: SSH, authentication, encryption

#### Validator Permissions:
- **Complete validator management**: Install, configure, upgrade, remove
- **Service control**: Start, stop, restart, enable, disable
- **Configuration management**: All validator configuration files
- **Monitoring setup**: Install and configure monitoring tools

#### Restrictions:
- None (full system access)

---

### 2. 🔑 validator_admins
**Description**: Complete validator management without system access

#### Validator Permissions:
- **Installation/Uninstallation**: Install and remove validator software
- **Configuration management**: Modify all validator configuration files
- **Service management**: Start, stop, restart validator services
- **Key management**: Generate, import, export validator keys
- **Upgrade management**: Update validator software and dependencies
- **Log management**: Access and configure validator logs
- **Monitoring setup**: Install and configure validator monitoring
- **Build Environment**: Install build prerequisites (libssl-dev, libudev-dev, pkg-config, zlib1g-dev, llvm, clang, cmake, make, libprotobuf-dev, protobuf-compiler)
- **Source Code Management**: Clone, pull, and manage Jito-Solana repository
- **Compilation**: Build Jito-Solana from source using Rust toolchain
- **Version Management**: Manage multiple Jito-Solana versions and symlinks
- **Configuration**: Modify Jito-specific validator startup scripts
- **MEV Configuration**: Configure block engine, relayer, and shred receiver settings
- **Service Configuration**: Create and modify systemd service files for Jito validators
- **Key Generation**: Generate hot-spare identity keys and manage key symlinks
- **Log Management**: Configure log rotation and monitoring for Jito validators

#### Directory Access:
- **Full access**: All validator directories and files
- **Configuration files**: Read, write, modify
- **Key files**: Read, write
- **Log files**: Read, write, rotate, archive
- **Data directories**: Read, write

#### Sudo Permissions:
**Sudoers File**: `/etc/sudoers.d/20-validator-admins`
```bash
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl start sol.service
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop sol.service
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart sol.service
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl enable sol.service
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl disable sol.service
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/apt-get install *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/apt-get update
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/snap install *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/curl *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/wget *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/git *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/cargo *
%validator_admins {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/rustup *
```


#### Restrictions:
- **No system access**: Cannot modify system configuration outside validator scope
- **No user management**: Cannot create or modify system users
- **No network configuration**: Cannot modify network settings
- **No disk management**: Cannot partition or format disks

---

### 3. ⚙️ validator_operators
**Description**: Operational tasks without installation/uninstallation capabilities

#### Operational Permissions:
- **Service control**: Start, stop, restart validator services
- **Status monitoring**: Check validator status and health
- **Log viewing**: Read and analyze validator logs
- **Performance monitoring**: Monitor validator performance metrics
- **Configuration viewing**: Read (but not modify) configuration files
- **Key viewing**: View (but not modify) validator keys
- **Update execution**: Run pre-approved updates

#### Directory Access:
- **Read access**: All validator directories and files
- **Execute access**: Scripts and binaries
- **Log access**: Read and analyze log files
- **Configuration access**: Read configuration files

#### Sudo Permissions:
**Sudoers File**: `/etc/sudoers.d/30-validator-operators`
```bash
%validator_operators {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl start sol.service
%validator_operators {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop sol.service
%validator_operators {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart sol.service
%validator_operators {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl status sol.service
%validator_operators {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/journalctl -u sol.service *
```



#### Restrictions:
- **No installation**: Cannot install or uninstall validator software
- **No configuration changes**: Cannot modify configuration files
- **No key management**: Cannot generate or modify keys
- **No system access**: Cannot access system-level operations

---

### 4. 👁️ validator_viewers
**Description**: Read-only access for monitoring and status checking

#### View Permissions:
- **Status viewing**: Check validator service status
- **Log viewing**: Read validator logs (read-only)
- **Configuration viewing**: Read configuration files (read-only)
- **Performance viewing**: View performance metrics and statistics
- **Key viewing**: View public keys (read-only)
- **Directory browsing**: Browse validator directories (read-only)

#### Directory Access:
- **Read-only access**: All validator directories and files
- **No write access**: Cannot modify any files
- **No execute access**: Cannot run scripts or binaries

#### Sudo Permissions:
**Sudoers File**: `/etc/sudoers.d/40-validator-viewers`
```bash
%validator_viewers {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/systemctl status sol.service
%validator_viewers {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/journalctl -u sol.service --no-pager
%validator_viewers {{ solana_user }} ALL=(ALL) NOPASSWD: /usr/bin/tail -f /var/log/solana/validator.log
```



#### Restrictions:
- **Read-only access**: Cannot modify any files or configurations
- **No service control**: Cannot start, stop, or restart services
- **No system access**: Cannot access system-level operations

---

## Multi-User Server Management

### Overview
The validator server supports multiple users with different roles, allowing for distributed responsibility and enhanced security through separation of duties.

### User Structure Example
```
Server Users:
- alice (sysadmin + validator_admins)
- bob (validator_operators + validator_viewers)
- carlos (validator_admins)
- alan (validator_viewers)
```

### User Role Matrix

| User | sysadmin | validator_admins | validator_operators | validator_viewers |
|------|----------|------------------|-------------------|-------------------|
| alice | ✅ | ✅ | ✅ | ✅ |
| carlos | ❌ | ✅ | ✅ | ✅ |
| bob | ❌ | ❌ | ✅ | ✅ |
| alan | ❌ | ❌ | ❌ | ✅ |

### Security Considerations

#### Separation of Duties
- **alice**: Can do everything but focuses on system administration
- **carlos**: Can manage validators but cannot modify system configuration
- **bob**: Can operate validators but cannot install or configure
- **alan**: Can monitor but cannot make any changes

#### Concurrent Access Management
- Multiple users can access the system simultaneously
- Each user operates within their assigned role boundaries
- No conflicts between different user roles
- Audit logs track all actions by user

### Playbook Execution Scenarios

#### Scenario 1: Jito Validator Installation
- **User**: carlos (validator_admins)
- **Playbook**: jito-install.yml
- **Role Enforcement**: validator_admins only
- **Expected Outcome**: Successful installation with admin privileges

#### Scenario 2: Validator Status Check
- **User**: alan (validator_viewers)
- **Playbook**: validator-status.yml
- **Role Enforcement**: validator_viewers only
- **Expected Outcome**: Status report with read-only access

#### Scenario 3: System Update
- **User**: alice (sysadmin)
- **Playbook**: system-update.yml
- **Role Enforcement**: sysadmin only
- **Expected Outcome**: System update with full privileges

### Benefits of Multi-User Structure

#### Security
- **Reduced Risk**: No single point of failure
- **Audit Trail**: Complete accountability for all actions
- **Least Privilege**: Each user has minimum necessary access
- **Separation of Duties**: Clear role boundaries

#### Scalability
- **Easy Expansion**: Add new users with appropriate roles
- **Role Flexibility**: Users can have multiple roles as needed
- **Process Standardization**: Consistent procedures across users
- **Documentation**: Role-specific documentation and procedures

---

## Implementation Strategy

### Role Hierarchy
```
sysadmin (Full access)
    ↓
validator_admins (Validator management)
    ↓
validator_operators (Operational tasks)
    ↓
validator_viewers (Read-only access)
```

### Group Management
- **Dynamic GID assignment**: System automatically assigns Group IDs
- **No hardcoded GIDs**: Avoids conflicts and simplifies deployment
- **Consistent naming**: Standardized group names across all systems

### Permission Inheritance
- Higher-level roles inherit permissions from lower-level roles
- Users can belong to multiple roles simultaneously
- Role enforcement ensures minimum privilege principle

---

## Ansible Playbook Integration

### Role Enforcement Strategy

When a user has multiple roles, the playbook can enforce the use of a specific role to ensure the principle of least privilege.

#### Example Scenario:
- **User**: `bob`
- **Bob's Roles**: `validator_viewers` + `validator_operators` + `validator_admins`
- **Playbook Requirement**: Only needs `validator_viewers` privileges
- **Goal**: Ensure Bob only uses viewer privileges, not operator or admin privileges

#### Implementation Logic:

1. **Role Verification**: Playbook verifies that Bob has the required `validator_viewers` role
2. **Privilege Restriction**: Playbook enforces the use of only viewer-level permissions
3. **Audit Logging**: All actions are logged with the enforced role context
4. **Error Prevention**: Playbook fails if Bob tries to execute tasks beyond viewer scope

#### Benefits:
- **Security**: Prevents privilege escalation even when user has higher roles
- **Compliance**: Ensures audit trails show correct privilege usage
- **Flexibility**: Allows users with multiple roles to work safely
- **Transparency**: Clear documentation of which role is being used

### Playbook Structure

#### Role-Specific Playbooks:
- **viewer-playbooks/**: Read-only operations and monitoring
- **operator-playbooks/**: Service control and operational tasks
- **admin-playbooks/**: Installation, configuration, and management
- **sysadmin-playbooks/**: System-level operations and maintenance

#### Execution Context:
- Each playbook specifies the required role
- Role verification happens at playbook start
- Privilege enforcement throughout execution
- Audit logging for all operations

---

## Security Best Practices

### 1. Principle of Least Privilege
- Always use the minimum required privileges for each task
- Regularly review and audit user permissions
- Remove unnecessary role assignments

### 2. Role Enforcement
- Implement role enforcement in all playbooks
- Verify role membership before executing tasks
- Log all role-based actions for audit purposes

### 3. Regular Audits
- Monthly review of user role assignments
- Quarterly permission audits
- Annual security assessments

### 4. Access Control
- Use strong authentication methods
- Implement session timeouts
- Monitor for suspicious activities

### 5. Documentation
- Maintain up-to-date role documentation
- Document all permission changes
- Keep audit logs for compliance

### 6. Multi-User Security
- Implement user session management
- Monitor concurrent user activities
- Establish clear communication protocols
- Regular user access reviews

---

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors
**Problem**: User cannot execute required commands
**Solution**: Verify user belongs to correct role group

#### 2. Role Enforcement Failures
**Problem**: Playbook fails role verification
**Solution**: Check user's group membership and sudoers configuration

#### 3. Service Control Issues
**Problem**: Cannot start/stop validator services
**Solution**: Verify sudo permissions for service control commands

#### 4. Directory Access Issues
**Problem**: Cannot access validator directories
**Solution**: Check directory ownership and group permissions

### Debugging Commands

#### Check User Roles:
```bash
# Check user's group membership
id username

# Check sudo permissions
sudo -l -U username

# Verify group existence
getent group groupname
```

#### Check Permissions:
```bash
# Check directory permissions
ls -la /path/to/directory

# Check file permissions
ls -la /path/to/file

#### Check Multi-User Activity:
```bash
# Check current user sessions
who

# Check recent user activity
last

# Check sudo usage by user
sudo grep username /var/log/auth.log
```
