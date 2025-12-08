# Localnet tests

These shell-based checks are driven by [Bats](https://github.com/bats-core/bats-core).

## Install Bats

- macOS (Homebrew): `brew install bats-core`
- npm: `npm install -g bats`

## Run

From repo root:

```sh
bats solana-localnet/tests/localnet.bats
```

## Expected runtime

- First run: 10–20 minutes for image builds; up to 45–60 minutes if Solana CLI needs compilation.
- Subsequent runs: typically 2–5 minutes if images are already built.
- Avoid cancelling long-running builds; set generous timeouts on first run.

You can also run the helpers directly:

```sh
bash solana-localnet/tests/test-localnet.sh podman   # or docker
```
