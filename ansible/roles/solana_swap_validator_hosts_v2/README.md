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

- Keys directory: `{{ validator_key_store }}/{{ validator_name }}` → `/opt/validator/keys/{{ validator_name }}`
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

- SSH keys: Generated in operator user's home directory (`{{ ansible_env.HOME }}/.ssh/validator_swap_id_rsa`) on the source host
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
|----------------|---------------|
| `solana_install_dir` | `system_solana_active_release_dir` |
| `build_dir` | `system_shared_build_dir` |
| N/A (not used) | `validator_root_dir` |
| `solana_user_dir` | N/A (not used) |
| `scripts_dir` | `validator_scripts_dir` |
| `logs_dir` | `validator_logs_dir` |
| `keys_dir` | `validator_key_store` |
| `default_group` | `validator_operators_group` |
| `default_file_mode` | `validator_key_file_mode` |
| `default_directory_mode` | `validator_data_mode_owner_readonly` |

## Order of operations to perform a validator Identity swap

Validator host swap operation happens in `tasks/swap.yml`. Here is a step by step description:

1. **Wait for Restart Window and Unstake Source Validator**
   - First, it waits for a safe restart window on the source validator using `agave-validator wait-for-restart-window`
   - Then it switches the source validator to use its hot-spare identity
   - Finally, it updates the identity symlink to point to the hot-spare identity
   - The symlink ownership is set to `sol:validator_operators` with appropriate permissions
   - This effectively takes the source validator out of active voting
   - **RBAC Note**: All `agave-validator` commands are executed with `become: true` and `become_user: "{{ solana_user }}"` because the validator binary requires access to ledger files and other resources that only the `sol` service user has permission to access

2. **Transfer Tower File**
   - Gets the tower filename by checking the primary target identity's public key
   - Uses rsync to copy the tower file from source to destination
   - The tower file is important for PoH (Proof of History) verification
   - **SSH Management for RBAC-Enabled Hosts**:
     - SSH keys are generated in the operator's home directory (`{{ ansible_env.HOME }}/.ssh/validator_swap_id_rsa`) on the source host, not in the `sol` user's directory
     - The public key is authorized for the operator user account on the destination host (not for `sol`), since operators SSH as their own accounts in RBAC environments
     - The rsync command uses the operator's SSH key with specific options to bypass host key verification:
       - `-o StrictHostKeyChecking=no` - Disables strict host key checking
       - `-o UserKnownHostsFile=/dev/null` - Bypasses the known_hosts file entirely
       - `-o CheckHostIP=no` - Disables IP address checking
       - `-o BatchMode=yes` - Prevents interactive prompts
     - Before rsync, any conflicting known_hosts entries are removed to prevent verification failures
     - An SSH connection test is performed first to verify connectivity before attempting the file transfer
   - **Legacy vs RBAC**: In legacy hosts, SSH keys were stored in `/home/sol/.ssh/` and authorized for the `sol` user. In RBAC-enabled hosts, keys are in the operator's home directory and authorized for the operator user account

3. **Promote Destination to Primary Target Validator**
   - Switches the destination validator to use the primary target identity
   - Updates the identity symlink on the destination to point to the primary target identity
   - The symlink ownership is set to `sol:validator_operators` with appropriate permissions
   - This effectively makes the destination validator the new primary validator
   - **RBAC Note**: The `agave-validator set-identity` command is executed with `become: true` and `become_user: "{{ solana_user }}"` for the same permission reasons as step 1

### RBAC-Specific Considerations

This role is designed for RBAC-enabled validator hosts and uses the following RBAC-specific configurations:

- **Key Storage**: Keys are stored in `{{ validator_key_store }}/{{ validator_name }}` (typically `/opt/validator/keys/{{ validator_name }}`)
- **Binary Paths**: Solana binaries are accessed from `{{ system_solana_active_release_dir }}` (system-wide installation)
- **File Ownership**: All identity files and symlinks are owned by `sol:validator_operators`
- **File Permissions**: Key files use `{{ validator_key_file_mode }}` (0464) for secure group-based access
- **SSH Keys**:
  - SSH keys for host-to-host communication are generated in the operator's home directory (`{{ ansible_env.HOME }}/.ssh/validator_swap_id_rsa`) on the source host
  - The public key is authorized for the operator user account on the destination host (not `sol`), since operators SSH as their own accounts
  - The rsync transfer uses the operator's SSH key with options to bypass host key verification for seamless operation
- **Privilege Escalation**:
  - The playbook runs as `become: false` by default, with operators running tasks as their own user accounts
  - Only specific tasks that require access to validator resources (like `agave-validator` commands) use `become: true` with `become_user: "{{ solana_user }}"` to run as the `sol` service user
  - This follows the principle of least privilege: operators only escalate when necessary

### Validations

- The playbook input parameters `source_host`, `destination_host`, `source_validator_name` and `destination_validator_name` are required. This is enforced during the precheck (`tasks/precheck.yml`) to ensure that the playbook goal can be achieved.
- Summary of what will happen is presented before executing the swap
- Keys may have the new naming convention or the old naming convention in the swap source host
  Allows for a grace period to support old naming convention in the swap source host (`tasks/prepare.yml`)
- Keys on the swap source host may be different than those on the swap destination host
  The playbook enforces that both validator hosts contain the same key set to avoid spinning a different validator identity
- Both source and destination hosts must be RBAC-enabled (this role does not support legacy hosts)
