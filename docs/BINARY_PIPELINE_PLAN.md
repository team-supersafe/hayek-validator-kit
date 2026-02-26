# Solana Binary Pipeline Plan

## Goal

Stop laptop-dependent binary publishing for Agave/Jito/Firedancer by making GitHub Actions the canonical build and release path.

## Non-Goals (Current)

- No immediate replacement of existing local scripts.
- No production cluster behavior change in this phase.
- No release-path publish in PR-3.
- No OIDC/S3 publish enforcement in PR-3.

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

1. PR-1 (completed)
- Add pipeline architecture documentation.
- Add workflow scaffold with manual dispatch and matrix planning.
- Default to dry-run mode (no publish side effects).

2. PR-2 (completed)
- Implement CI build jobs for `agave` and `jito-solana` on `x86_64` and `aarch64`.
- Generate `manifest.json` as workflow artifact.

3. PR-3 (completed)
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
  - `solana-localnet/build-solana-cli/build-cli-no-upload.sh`
  - `solana-localnet/build-solana-cli/build-solana-cli-and-upload-to-s3.sh`
  - `solana-localnet/build-solana-cli/build-jito-solana-cli-and-upload-to-s3.sh`
  - `solana-localnet/build-solana-cli/upload-solana-binaries-to-s3.sh`
  - `solana-localnet/build-solana-cli/run-build-in-container.sh`

- Workflow:
  - `.github/workflows/solana-binary-pipeline.yml`

## Current Workflow Behavior (PR-3)

- Trigger: manual `workflow_dispatch`.
- Inputs: `client`, `version`, `arch`, `dry_run`, `publish_staging`, `s3_bucket`, `aws_region`, `staging_prefix`.
- Matrix: `{agave,jito-solana} x {x86_64,aarch64}` (filtered by inputs).
- Runner requirement: ARM builds use `ubuntu-24.04-arm` GitHub runner availability.
- Builds:
  - Runs `build-cli-no-upload.sh` per matrix item.
  - Produces `solana-release-<arch>-unknown-linux-gnu.tar.bz2`.
  - Produces per-item metadata JSON with checksum and target S3 key.
  - Produces per-item `<archive>.sha256` checksum sidecar.
- Artifacts:
  - `build-archive-<client>-<arch>-v<version>`
  - `build-meta-<client>-<arch>-v<version>`
  - `build-checksum-<client>-<arch>-v<version>`
  - `build-manifest-v<version>` containing aggregated `manifest.json`
  - `build-manifest-sha256-v<version>`
- Staging publish (optional):
  - Enabled with `publish_staging=true`.
  - Uploads archives and `.sha256` files to `s3://<bucket>/<staging_prefix>/<release_key>`.
  - Uploads staging manifest to `s3://<bucket>/<staging_prefix>/manifests/solana-binary-manifest-v<version>.json` (+ `.sha256`).
  - Uses repository secrets:
    - `SOLANA_BINARY_UPLOAD_AWS_ACCESS_KEY_ID`
    - `SOLANA_BINARY_UPLOAD_AWS_SECRET_ACCESS_KEY`
- Explicitly not included yet: release-path publish and promotion workflow (PR-4+).
