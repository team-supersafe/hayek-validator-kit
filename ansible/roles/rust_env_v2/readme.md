
# rust_env_v2 Ansible Role

This role installs, configures, and verifies a system-wide Rust development environment on the target host. It is not tied to any validator or Solana-specific directory structure and is suitable for any host that needs Rust/Cargo.

## Tasks
- **Install Rust**: Installs the specified Rust toolchain version using rustup.
- **Configure Environment**: Sets up environment variables and configuration for Rust in a system-wide location.
- **Verify Installation**: Checks that Rust is installed and configured correctly.

## Role Variables
- `cargo_home` (default: `/usr/local/cargo`): System-wide Cargo home directory. Should be set globally in `group_vars/all.yml`.
- `rustup_home` (default: `/usr/local/rustup`): System-wide Rustup home directory. Should be set globally in `group_vars/all.yml`.

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
  become: yes
  roles:
    - role: rust_env_v2
```

## Global Variable Setup
Add these to `ansible/group_vars/all.yml` for system-wide installation:

```yaml
cargo_home: "/usr/local/cargo"
rustup_home: "/usr/local/rustup"
```
