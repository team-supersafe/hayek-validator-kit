# common Ansible Role

This role contains tasks, configurations, and handlers that are shared across multiple roles or hosts in your Ansible playbooks.

## Purpose
The `common` role is used to set up baseline system settings and perform general configuration steps that are required by all nodes, regardless of their specific function.

## Typical Contents
- Installing essential packages
- Creating common users and groups
- Setting up basic security configurations (e.g., SSH, firewalls)
- Configuring system-wide environment variables
- Applying general system updates
- Any other tasks that should be applied to all hosts

## Usage
Include this role at the beginning of your playbook to ensure all hosts have a consistent baseline configuration.

```yaml
- hosts: all
  roles:
    - common
```
