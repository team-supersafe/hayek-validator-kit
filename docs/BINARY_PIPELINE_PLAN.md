# Solana Binary Pipeline Plan

## Goal

Stop laptop-dependent binary publishing for Agave/Jito/Firedancer by making GitHub Actions the canonical build and release path.

## Non-Goals (PR-1 Scaffold)

- No immediate replacement of existing local scripts.
- No production cluster behavior change in this PR.
- No immediate OIDC role enforcement in this PR.

## Current State

- Team members manually build binaries from local machines.
- Build outputs depend on local host architecture and environment.
- Uploads are manual and credentials are user-managed.
- Automated tests often rely on pre-built binaries for speed.

## Target State

- CI builds architecture-specific artifacts in a reproducible workflow.
- CI generates a manifest with metadata (`client`, `version`, `arch`, `sha256`, `url`).
- CI is the only approved publisher to S3 release paths.
- Local scripts remain as fallback/dev tooling, not the release source of truth.

## Policy

- Localnet/dev tests may use pre-built binaries (`build_from_source=false`) for speed.
- Production clusters (`testnet`, `mainnet`) must always use `build_from_source=true`.

## Incremental PR Sequence

1. PR-1 (this scaffold)
- Add pipeline architecture documentation.
- Add workflow scaffold with manual dispatch and matrix planning.
- Default to dry-run mode (no publish side effects).

2. PR-2
- Implement CI build jobs for `agave` and `jito-solana` on `x86_64` and `aarch64`.
- Generate `manifest.json` as workflow artifact.

3. PR-3
- Add S3 staging publish (`staging/` paths) and checksum outputs.
- Keep release publish behind manual approval.

4. PR-4
- Add promotion workflow from staging to release paths (no rebuild).
- Add release manifest publication.

5. PR-5
- Enforce CI-only publishing via GitHub OIDC role and S3 policy.
- Block production playbooks from `build_from_source=false`.

## Source Paths Used By Pipeline

- Build scripts:
  - `solana-localnet/build-solana-cli/build-solana-cli-and-upload-to-s3.sh`
  - `solana-localnet/build-solana-cli/build-jito-solana-cli-and-upload-to-s3.sh`
  - `solana-localnet/build-solana-cli/upload-solana-binaries-to-s3.sh`
  - `solana-localnet/build-solana-cli/run-build-in-container.sh`

- Workflow scaffold:
  - `.github/workflows/solana-binary-pipeline.yml`
