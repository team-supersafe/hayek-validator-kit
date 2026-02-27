# AGENTS.md

## Cursor Cloud specific instructions

### Overview

The Hayek Validator Kit is an Ansible-based infrastructure toolkit for deploying and managing Solana validators. There is no JavaScript/TypeScript, no `package.json`, and no Node.js dependency. The primary tools are Python (Ansible, pre-commit), Docker/Docker Compose, and Bash.

### Lint & Validation

- **Lint**: `pre-commit run --all-files` (from repo root). First run will fail on existing shellcheck warnings — this is expected per `.github/copilot-instructions.md`. Pre-commit auto-fixes whitespace/EOF issues; reset those changes with `git checkout -- .` if you are not supposed to modify existing code.
- **Ansible syntax check**: Run from `ansible/` directory. The main playbook is `playbooks/pb_setup_metal_box.yml`. Playbooks that use templated hosts (e.g. `{{ target_host }}`) require `-e target_host=localhost` for offline syntax checking.

  ```bash
  cd ansible && ansible-playbook --syntax-check playbooks/pb_setup_metal_box.yml -e target_host=localhost
  ```

- **ansible-lint / yamllint**: Available via `pip install ansible-lint yamllint` for deeper Ansible linting.

### Running the Localnet (Docker Compose)

Three env vars must be set before any `docker compose` command in `solana-localnet/`:

```bash
export COMPOSE_PROJECT_NAME=hayek-localnet
export ANSIBLE_REMOTE_USER=testuser
export SSH_AUTH_SOCK=/dev/null
```

- Validate config: `docker compose config --quiet`
- Build images: `docker compose --profile localnet build` (takes ~2 min on cached, ~10-20 min on first build)
- Start: `docker compose --profile localnet up -d`
- Status: `docker compose --profile localnet ps`
- Solana RPC health: `curl http://localhost:8899/health`

The `solana_setup_host.yml` and `solana_new_metal_box.yml` files in `ansible/` root are **inventory files**, not playbooks, despite the `.yml` extension. Do not pass them to `ansible-playbook --syntax-check`.

### Docker-in-Docker Caveats

The Cloud Agent VM runs inside a Firecracker VM with Docker-in-Docker. Key requirements:

- `fuse-overlayfs` must be the Docker storage driver (configured via `/etc/docker/daemon.json`).
- `iptables-legacy` must be the active alternative (`update-alternatives --set iptables /usr/sbin/iptables-legacy`).
- The Solana test validator may be slow to produce blocks in this nested environment due to resource constraints. The RPC endpoint will be healthy and responsive even if block height stays at 0 for an extended period.

### Molecule Tests (ansible-tests/)

Molecule tests run inside Docker containers defined in `ansible-tests/docker-compose.yml`. They require Docker and the Docker socket. See `ansible-tests/README.md` for full instructions.

### Key Paths

- Ansible roles: `ansible/roles/`
- Playbooks: `ansible/playbooks/`
- Localnet Docker setup: `solana-localnet/`
- Molecule tests: `ansible-tests/`
- Copilot/AI instructions: `.github/copilot-instructions.md` (comprehensive reference for build/test/validation steps)
