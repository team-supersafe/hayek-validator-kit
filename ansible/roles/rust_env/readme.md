# rust_env Ansible Role

This role installs, configures, and verifies a Rust development environment on the target host.

## Tasks
- **Install Rust**: Installs the specified Rust toolchain version.
- **Configure Environment**: Sets up environment variables and configuration for Rust.
- **Verify Installation**: Checks that Rust is installed and configured correctly.

## Role Variables
- `rust_version` (required): The version of Rust to install (e.g., `stable`, `nightly`, or a specific version).
- `rust_verify` (optional, default: `true`): Whether to run verification steps after installation.

## Tags
- `rust`: All tasks in this role
- `install`: Only installation tasks
- `config`: Only configuration tasks
- `verify`: Only verification tasks
- `done`: Final status message
- `prereq`: Prerequisite checks

## Example Usage
```yaml
- hosts: all
  roles:
    - role: rust_env
      vars:
        rust_version: stable
        rust_verify: true
```
