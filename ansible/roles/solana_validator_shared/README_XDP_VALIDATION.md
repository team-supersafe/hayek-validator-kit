# Shared XDP Validation Guide

This guide documents how to validate the shared XDP procedure without doing a full validator setup.

## Purpose

The playbook `playbooks/pb_validate_xdp_shared.yml` validates:

- XDP request toggles and version gating
- kernel/tool/bpffs preflight checks
- XDP flag support probing in the installed validator binary
- computed XDP params that would be merged into validator startup args

Important:

- This validates **configuration/preflight and flag support logic**
- This does **not** validate sustained runtime packet-path behavior under load

## Run the Validation

From `ansible/`:

```bash
ANSIBLE_LOCAL_TEMP=/tmp/.ansible-local \
ansible-playbook playbooks/pb_validate_xdp_shared.yml \
  -i solana_setup_host.yml \
  --limit validator-host \
  -e "target_host=validator-host" \
  -e "ansible_user=<sysadmin_user>" \
  -K
```

Optional deterministic assertion run:

```bash
ANSIBLE_LOCAL_TEMP=/tmp/.ansible-local \
ansible-playbook playbooks/pb_validate_xdp_shared.yml \
  -i solana_setup_host.yml \
  --limit validator-host \
  -e "target_host=validator-host" \
  -e "ansible_user=<sysadmin_user>" \
  -e "xdp_enabled=false" \
  -e "expected_xdp_effective_enabled=false" \
  -e "expected_xdp_skip_reason=xdp_disabled" \
  -K
```

## How This Connects to Validator Setup Playbooks

XDP shared logic is already wired into both setup roles:

- `playbooks/pb_setup_validator_agave.yml`
- `playbooks/pb_setup_validator_jito_v2.yml`

Default behavior:

- No extra XDP variables are required.
- XDP is default-on (`xdp_enabled=true`).
- If supported on host/binary, XDP params are injected into validator startup.
- If unsupported, behavior is fail-open: validator setup/startup continues with explicit warnings and no XDP params injected.

Optional override variables:

- Disable explicitly:
  - `-e "xdp_enabled=false"`
- Set mode (when relevant to supported flags):
  - `-e "xdp_mode=native"`
- Tune experimental retransmit cores:
  - `-e "xdp_experimental_retransmit_xdp_cpu_cores=1"`
- Toggle experimental zero-copy:
  - `-e "xdp_experimental_retransmit_xdp_zero_copy=true"`

## How to Read the Summary

Example success-style summary:

```text
XDP Validation Summary
- Validator: validator-host
- Requested: True
- Effective: True
- Primary reason:
- All reasons: none
- Computed params: --experimental-retransmit-xdp-cpu-cores 1 --experimental-retransmit-xdp-zero-copy
- Validator version: 3.1.8
- Kernel semver: 6.8.0
```

Interpretation:

- `Requested=True`: XDP was requested (`xdp_enabled=true`)
- `Effective=True`: shared logic produced supported XDP args
- `Computed params`: flags that will be appended to validator startup args
- `Validator version` and `Kernel semver`: key compatibility checks used by preflight

Example preflight-only non-effective summary:

```text
XDP Validation Summary
- Requested: True
- Effective: False
- Primary reason: xdp_flags_unavailable
- All reasons: xdp_flags_unavailable
```

Interpretation:

- Host passed basic checks, but tested binary does not accept any supported XDP flags
- XDP params are not injected in this case (fail-open behavior)

## Common Reasons

- `xdp_disabled`
  - Explicitly disabled by input (`xdp_enabled=false`)
- `validator_version_unsupported`
  - Installed validator version is below minimum supported version (`>= 3.0.9`)
- `xdp_flags_unavailable`
  - Probe could not find any accepted XDP flags in the installed binary
- `kernel_too_old`
  - Kernel version check failed against configured minimum
- `bpffs_unavailable`
  - `/sys/fs/bpf` not present on target host
- `missing_tools_ip_ethtool`
  - Required tools for checks are missing

## Next Layer of Validation (After This Passes)

After this playbook passes, validate runtime behavior in staged rollout:

- canary node startup with real service
- observe validator logs and host metrics
- confirm no regressions during sustained operation window
