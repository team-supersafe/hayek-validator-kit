# Shared XDP Validation Guide

This guide documents how to validate the shared XDP procedure without doing a full validator setup.

## Purpose

The playbook `playbooks/pb_validate_xdp_shared.yml` validates:

- XDP request toggles and version gating
- kernel/tool/bpffs preflight checks
- XDP flag support probing in the installed validator binary
- computed XDP params that would be merged into validator startup args
- NUMA placement assessment between PoH core and XDP retransmit core list

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
- Force interface selection for XDP preflight checks:
  - `-e "xdp_target_interface=eno1"`
- Toggle NUMA placement assessment:
  - `-e "xdp_numa_check_enabled=true"`

## How to Read the Summary

Example success-style summary:

```text
XDP Validation Summary
- Validator: validator-host
- Requested: True
- Effective: True
- Primary reason: none
- All reasons: none
- Computed params: --experimental-retransmit-xdp-cpu-cores 1 --experimental-retransmit-xdp-zero-copy
- Validator version: 3.1.8
- Kernel semver: 6.8.0
- NUMA check: ok (none)
- PoH core/node: 10/1
- XDP cores/nodes: 1/0
- Interface: eno1
- Interface source: auto
- Interface driver link present: True
- Capability source: systemd_unit
- Capability confidence: high
```

Interpretation:

- `Requested=True`: XDP was requested (`xdp_enabled=true`)
- `Effective=True`: shared logic produced supported XDP args
- `Computed params`: flags that will be appended to validator startup args
- `Validator version` and `Kernel semver`: key compatibility checks used by preflight
- `NUMA check`: `ok|warn|skip` for PoH/XDP placement confidence
- `Interface source`: `override|auto` to clarify whether operator override was used
- `Capability source`: `systemd_unit|proc_self_fallback` to clarify confidence in capability gating

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
- `missing_caps_net_admin_net_raw_bpf_perfmon` (or subset)
  - Required Linux capabilities for XDP retransmit are not available in capability bounding set
- `xdp_interface_unresolved`
  - No primary interface could be resolved from host routing
- `xdp_interface_missing_<iface>`
  - Operator-specified interface or auto-selected interface was not found on host
- `xdp_interface_driver_unavailable_<iface>`
  - Interface exists but driver link is not available (common in some container/veth environments)
- `same_numa_node` / `same_cpu` / `shared_physical_core`
  - XDP and PoH core choices may contend; setup continues (warn-only) but placement should be corrected
- `poh_core_unset_or_disabled`
  - PoH pinning is disabled/unset, so NUMA relation to PoH cannot be fully assessed
- `single_numa_host`
  - Host exposes only one NUMA node; cross-NUMA separation cannot be enforced (informational skip)

## Choosing PoH and XDP cores safely

Practical guidance for teams:

- `--experimental-retransmit-xdp-cpu-cores` takes CPU ids/list/ranges (`CPU_LIST`), not a count.
  - Example: `1` means CPU id 1.
  - Example: `1,9-10` means CPU ids 1, 9, and 10.
- Keep XDP core(s) and PoH core on different NUMA nodes when possible.
- Avoid placing XDP on the same CPU id as PoH.
- Avoid placing XDP on PoH SMT sibling (same physical core pair).
- Keep one explicit PoH core in vars (`poh_pinned_cpu_core`) and one explicit XDP CPU list (`xdp_experimental_retransmit_xdp_cpu_cores`) per hardware profile.

## Next Layer of Validation (After This Passes)

After this playbook passes, validate runtime behavior in staged rollout:

- canary node startup with real service
- observe validator logs and host metrics
- confirm no regressions during sustained operation window
