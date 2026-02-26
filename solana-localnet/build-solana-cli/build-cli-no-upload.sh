#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: build-cli-no-upload.sh <client> <version> <arch> <output_dir> [metadata_json]
  client: agave | jito-solana
  version: semantic version without leading v (example: 3.0.14)
  arch: x86_64 | aarch64
  output_dir: directory where archive will be written
  metadata_json: optional output metadata path (JSON)
EOF
}

if [[ $# -lt 4 || $# -gt 5 ]]; then
  usage
  exit 2
fi

CLIENT="$1"
VERSION="$2"
ARCH="$3"
OUTPUT_DIR="$4"
METADATA_FILE="${5:-}"
S3_BASE_URL="${S3_BASE_URL:-https://solv-store.s3.us-east-1.amazonaws.com}"

case "$CLIENT" in
  agave|jito-solana) ;;
  *)
    echo "Unsupported client: $CLIENT (expected agave|jito-solana)" >&2
    exit 2
    ;;
esac

case "$ARCH" in
  x86_64|aarch64) ;;
  *)
    echo "Unsupported arch: $ARCH (expected x86_64|aarch64)" >&2
    exit 2
    ;;
esac

HOST_ARCH="$(uname -m)"
if [[ "$HOST_ARCH" != "$ARCH" ]]; then
  echo "Host architecture ($HOST_ARCH) does not match requested arch ($ARCH)." >&2
  echo "Run on a matching architecture runner." >&2
  exit 3
fi

for cmd in git cargo tar; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Required command '$cmd' not found in PATH." >&2
    exit 3
  fi
done

WORK_ROOT="$(mktemp -d)"
trap 'rm -rf "$WORK_ROOT"' EXIT
SRC_ROOT="$WORK_ROOT/src"
INSTALL_ROOT="$WORK_ROOT/install"
mkdir -p "$SRC_ROOT" "$INSTALL_ROOT" "$OUTPUT_DIR"

ARCHIVE_NAME="solana-release-${ARCH}-unknown-linux-gnu.tar.bz2"
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"

if [[ "$CLIENT" == "agave" ]]; then
  TAG="v${VERSION}"
  REPO_URL="https://github.com/anza-xyz/agave.git"
  SRC_DIR="$SRC_ROOT/agave"
  git clone --depth 1 --branch "$TAG" "$REPO_URL" "$SRC_DIR"
  (
    cd "$SRC_DIR"
    ./scripts/cargo-install-all.sh "$INSTALL_ROOT/solana-release"
  )
else
  TAG="v${VERSION}-jito"
  REPO_URL="https://github.com/jito-foundation/jito-solana.git"
  SRC_DIR="$SRC_ROOT/jito-solana"
  git clone --depth 1 --branch "$TAG" --recurse-submodules "$REPO_URL" "$SRC_DIR"
  (
    cd "$SRC_DIR"
    ./scripts/cargo-install-all.sh --validator-only "$INSTALL_ROOT/solana-release"
  )
fi

"$INSTALL_ROOT/solana-release/bin/agave-validator" --version
tar -cjf "$ARCHIVE_PATH" -C "$INSTALL_ROOT" solana-release

if command -v sha256sum >/dev/null 2>&1; then
  SHA256="$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  SHA256="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
else
  echo "Could not find sha256sum or shasum." >&2
  exit 3
fi

if [[ "$CLIENT" == "agave" ]]; then
  S3_KEY="agave/releases/download/v${VERSION}/${ARCHIVE_NAME}"
else
  S3_KEY="jito-solana/releases/download/v${VERSION}-jito/${ARCHIVE_NAME}"
fi

echo "Built archive: $ARCHIVE_PATH"
echo "sha256: $SHA256"

if [[ -n "$METADATA_FILE" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to write metadata file." >&2
    exit 3
  fi
  mkdir -p "$(dirname "$METADATA_FILE")"
  jq -n \
    --arg client "$CLIENT" \
    --arg version "$VERSION" \
    --arg arch "$ARCH" \
    --arg archive_name "$ARCHIVE_NAME" \
    --arg archive_path "$ARCHIVE_PATH" \
    --arg sha256 "$SHA256" \
    --arg s3_key "$S3_KEY" \
    --arg release_url "${S3_BASE_URL}/${S3_KEY}" \
    '{
      client: $client,
      version: $version,
      arch: $arch,
      archive_name: $archive_name,
      archive_path: $archive_path,
      sha256: $sha256,
      s3_key: $s3_key,
      release_url: $release_url
    }' >"$METADATA_FILE"
  echo "Wrote metadata: $METADATA_FILE"
fi
