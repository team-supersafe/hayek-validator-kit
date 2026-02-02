# Solana Validator Identity Swap for RBAC-Enabled Hosts

## Differences between legacy and RBAC-enabled validator hosts

### 1. Directory structure and paths

**Legacy hosts:**

- Keys directory: `{{ solana_user_dir }}/keys/{{ validator_name }}` → `/home/sol/keys/{{ validator_name }}`
- Solana binaries: `{{ solana_user_dir }}/.local/share/solana/install/active_release/bin` → `/home/sol/.local/share/solana/install/active_release/bin`
- Scripts: `{{ solana_user_dir }}/bin` → `/home/sol/bin`
- Logs: `{{ solana_user_dir }}/logs` → `/home/sol/logs`
- Build directory: `{{ solana_user_dir }}/build` → `/home/sol/build`
- Everything is under the `sol` user's home directory

**RBAC-enabled hosts:**

- Keys directory: `{{ validator_keys_dir }}/{{ validator_name }}` → `/opt/validator/keys/{{ validator_name }}`
- Solana binaries: `{{ system_solana_active_release_dir }}` → `/opt/solana/active_release/bin` (system-wide)
- Scripts: `{{ validator_scripts_dir }}` → `/opt/validator/scripts`
- Logs: `{{ validator_logs_dir }}` → `/opt/validator/logs`
- Centralized under `/opt/validator` and system-wide binaries

### 2. User and group model

**Legacy hosts:**

- `sol` is an interactive user (operators SSH as `sol`)
- Group: `{{ default_group }}` (typically `sol` or similar)
- All files owned by `sol:sol` (or similar)
- Single-user model

**RBAC-enabled hosts:**

- `sol` is a system service user (non-interactive, runs validator via systemd)
- Group: `{{ validator_operators_group }}` → `validator_operators`
- Files owned by `sol:validator_operators` with group permissions
- Multi-user RBAC: operators belong to `validator_operators`, viewers to `validator_viewers`
- Least privilege: operators can read/write, viewers can read

### 3. File permissions

**Legacy hosts:**

- File mode: `{{ default_file_mode }}` (typically `0600` or `0644`)
- Directory mode: `{{ default_directory_mode }}` (typically `0755` or `0700`)

**RBAC-enabled hosts:**

- Key files: `{{ validator_key_file_mode }}` → `0464` (owner read, group read, others none)
- Directories (read-only): `{{ validator_data_mode_owner_readonly }}` → `0575` (owner read/execute, group read/execute, others none)
- Directories (writable): `{{ validator_data_mode_owner_writable }}` → `2775` (setgid, owner/group read/write/execute)
- Stricter permissions with group-based access

### 4. Build environment

**Legacy hosts:**

- Cargo/rustup: user-specific paths under `sol` home directory → `/home/sol/.cargo` & `/home/sol/.rustup`
- Build tools: per-user installation

**RBAC-enabled hosts:**

- Cargo/rustup: system-wide under `/usr/local` (`{{ cargo_home }}`, `{{ rustup_home }}`) → `/usr/local/cargo` & `/usr/local/rustup`
- Build tools: centralized, shared by all operators
- Build directory: centralized verasion aware repository cloning `system_shared_build_dir` → `/opt/build`

### 5. SSH key handling

**Legacy hosts:**

- SSH keys: `{{ solana_user_dir }}/.ssh/id_rsa` → `/home/sol/.ssh/id_rsa`
- Authorized keys: `{{ solana_user_dir }}/.ssh/authorized_keys` → `/home/sol/.ssh/authorized_keys`
- Operators SSH directly as `sol` user
- For host-to-host communication during swaps, keys were authorized for the `sol` user on the destination host

**RBAC-enabled hosts:**

- SSH keys: Generated in operator user's home directory (`{{ ansible_facts['env']['HOME'] }}/.ssh/validator_swap_id_rsa`) on the source host
- Authorized keys: Per-operator user accounts (e.g., `/home/bob/.ssh/authorized_keys`)
- Operators SSH as their own user accounts (not `sol`)
- For host-to-host communication during swaps:
  - SSH key is generated in the operator's home directory on the source host
  - Public key is authorized for the operator user account on the destination host (not `sol`)
  - This allows the operator to SSH from source to destination using their own account
  - The rsync command uses the operator's SSH key with options to bypass host key verification, since operators may not have previously connected between these hosts
  - Known_hosts entries are cleaned up before transfer to prevent conflicts

### 6. Detection mechanism

RBAC detection checks for:

- `validator_root_dir` exists (`/opt/validator`)
- `cargo_home` exists (system-wide cargo)
- `rustup_home` exists (system-wide rustup)

All three must exist for `validator_rbac_enabled` to be `true`.

### 7. Variable mapping summary

| Legacy Variable | RBAC Variable |
| ---------------- | --------------- |
| `solana_install_dir` | `system_solana_active_release_dir` |
| `build_dir` | `system_shared_build_dir` |
| N/A (not used) | `validator_root_dir` |
| `solana_user_dir` | N/A (not used) |
| `scripts_dir` | `validator_scripts_dir` |
| `logs_dir` | `validator_logs_dir` |
| `keys_dir` | `validator_keys_dir` |
| `default_group` | `validator_operators_group` |
| `default_file_mode` | `validator_key_file_mode` |
| `default_directory_mode` | `validator_data_mode_owner_readonly` |


## Firewall and SSH Automation Notes

- This role uses the Ansible `ufw` module for idempotent firewall rule management. UFW rules are added for the source host's IP and the correct SSH port, and UFW is restarted and enabled as part of the process.
- SSH connectivity is tested robustly from the source host to the destination host. The play will fail if SSH access is not possible, ensuring firewall and key setup are correct before proceeding.

### Key Variables for Firewall/SSH Logic

| Variable                   | Purpose                                                      |
|----------------------------|--------------------------------------------------------------|
| `source_host_address`      | Source host's IP or hostname for UFW rule                    |
| `destination_host_address` | Destination host's IP or hostname for SSH connection         |
| `destination_host_port`    | SSH port on destination host (from inventory or default 22)  |

### Troubleshooting

- If SSH connectivity fails:
   - Ensure the operator's public key is present in the destination user's `authorized_keys` file.
   - Verify the UFW rule for the source host's IP and SSH port is present and active on the destination host.
   - Confirm that UFW is enabled and running.

## Order of operations to perform a validator Identity swap

### Summary of Checks Performed in `solana_swap_validator_hosts_v2` Before Confirming Swap

#### 1. Precheck Phase (`tasks/precheck.yml`)

- ✅ Validates source and destination hosts are different
- ✅ Validates validator directories exist on both hosts
- ✅ Ensures destination validator service is active and process is running
- ✅ Gets running ledger identities for both hosts (`source_ledger_identity`, `destination_ledger_identity`)
- ✅ Validates that ledger identity matches the running validator process identity

#### 2. Prepare Phase (`tasks/prepare.yml`)

- ✅ Validates RPC_URL for localnet
- ✅ Ensures enough time remaining in epoch before swap
- ✅ Sets up SSH keys for host-to-host communication
- ✅ Validates identity keypair files exist on both hosts
- ✅ Gets primary target identity pubkeys (`source_primary_pubkey`, `destination_primary_pubkey`)
- ✅ Validates that primary pubkeys match between hosts (both should have the same primary target identity)
- ✅ Checks if swap is already completed and fail if so
- ✅ Checks cluster delinquency levels
- ✅ Checks leader schedule to ensure safe restart window
- ✅ Ensures source host IP and SSH port are allowed in destination host's UFW rules using the Ansible `ufw` module (auto-added if missing)
- ✅ Tests SSH connectivity from source to destination (robust, fails on any error)
- ✅ Verifies destination validator health

#### 3. Confirm Swap Phase (`tasks/confirm_swap.yml`)

- ✅ Gets hot-spare identity pubkeys
- ✅ Gets vote account pubkeys
- ✅ Displays comprehensive swap operation summary
- ✅ Fails if primary identity pubkeys don't match (duplicate check)
- ✅ Prompts user for confirmation
- ✅ Fails if user doesn't confirm with 'yes'

#### 4. Swap Phase (`tasks/swap.yml`)

1. **Wait for Restart Window and Unstake Source Validator**
   - Waits for a safe restart window on the source validator using `agave-validator wait-for-restart-window`
   - Switches the source validator to use its hot-spare identity
   - Updates the identity symlink to point to the hot-spare identity
   - The symlink ownership is set to `sol:validator_operators` with appropriate permissions
   - This effectively takes the source validator out of active voting
   - **RBAC Note**: All `agave-validator` commands are executed with `become: true` and `become_user: "{{ solana_user }}"`

2. **Transfer Tower File**
   - Gets the tower filename by checking the primary target identity's public key
   - Uses rsync to copy the tower file from source to destination
   - The tower file is important for PoH (Proof of History) verification
   - **Firewall/ufw**: The ufw rule is removed from the destination host after a successful swap
   - **SSH Management for RBAC-Enabled Hosts**: SSH keys are generated in the operator's home directory, authorized for the operator user account, and all host key verification is bypassed for the transfer
   - An SSH connection test is performed first to verify connectivity before attempting the file transfer

3. **Promote Destination to Primary Target Validator**
   - Switches the destination validator to use the primary target identity
   - Updates the identity symlink on the destination to point to the primary target identity
   - The symlink ownership is set to `sol:validator_operators` with appropriate permissions
   - This effectively makes the destination validator the new primary validator
   - **RBAC Note**: The `agave-validator set-identity` command is executed with `become: true` and `become_user: "{{ solana_user }}"`

### Fast Rollback

If the swap fails after the source validator is demoted, follow the documented procedure in `FAST_ROLLBACK.md` to restore the primary identity and validator service on the source host.
