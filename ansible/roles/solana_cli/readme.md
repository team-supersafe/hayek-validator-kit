# solana_cli Ansible Role

This role installs, configures, and verifies the Solana CLI tools on the target host.

## Tasks
- **Install Solana CLI**: Downloads and installs the Solana CLI using the official install script.
- **Configure CLI**: Sets up configuration for the Solana CLI environment (default cluster URL is mainnet-beta).
- **Verify Installation**: Checks that the Solana CLI is installed and working correctly.

## Role Variables
- `solana_user` (optional, default: `sol` if available, otherwise `ansible_user_id`): The user account to install the CLI under.
- `solana_cli_bin_path` (optional, default: `$HOME/.local/share/solana/install/active_release/bin`): Path to the Solana CLI binaries.
- `solana_channel` (optional, default: `stable`): The release channel or version for the Solana CLI install script (e.g., `stable`, `beta`, `edge`, or a specific version like `v1.18.12`).

## Tags
- `solana_cli`: All tasks in this role
- `install`: Only installation tasks
- `config`: Only configuration tasks
- `verify`: Only verification tasks

## Example Usage
```yaml
- hosts: all
  roles:
    - role: solana_cli
      vars:
        solana_user: sol
        solana_channel: stable
```

## Prerequisites
- Supported OS: Ubuntu, macOS
- Ansible 2.9+ recommended
- Internet access to download Solana CLI binaries

## Dependencies
- `rust_env` role (if building from source)
