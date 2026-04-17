#!/usr/bin/env bash
# extract-cli-help.sh — recursively capture --help output for Solana/Agave CLI commands.
#
# Usage:
#   extract-cli-help.sh <bin_dir> <output_dir> <client> <version> <arch>
#
#   bin_dir:    path to directory containing the built binaries
#   output_dir: directory where cli-help-dump-<client>-<arch>.txt is written
#   client:     agave | jito-solana
#   version:    semantic version without leading v (e.g. 3.0.14)
#   arch:       x86_64 | aarch64
#
# Output: <output_dir>/cli-help-dump-<client>-<arch>.txt
#
# The file contains --help output for the following commands and all their
# subcommands (discovered recursively, max depth 5):
#   solana, solana-test-validator, agave-watchtower, agave-validator
#
# Entries are sorted alphabetically by command path so diffs between versions
# are stable regardless of help-text reordering.

set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: extract-cli-help.sh <bin_dir> <output_dir> <client> <version> <arch>
  bin_dir:    path to directory containing the built binaries
  output_dir: directory where cli-help-dump-<client>-<arch>.txt is written
  client:     agave | jito-solana
  version:    semantic version without leading v (e.g. 3.0.14)
  arch:       x86_64 | aarch64
EOF
}

if [[ $# -ne 5 ]]; then
  usage
  exit 2
fi

BIN_DIR="$1"
OUTPUT_DIR="$2"
CLIENT="$3"
VERSION="$4"
ARCH="$5"

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

if [[ ! -d "$BIN_DIR" ]]; then
  echo "bin_dir does not exist: $BIN_DIR" >&2
  exit 2
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="${OUTPUT_DIR}/cli-help-dump-${CLIENT}-${ARCH}.txt"

# Visited paths — prevents cycles in the rare case a binary has circular subcommand refs
VISITED_FILE="$WORK/visited.txt"
touch "$VISITED_FILE"

# All --help entries are written here; sorted alphabetically at the end
ENTRIES_FILE="$WORK/all.entries"
touch "$ENTRIES_FILE"

# Maximum recursion depth for subcommand discovery
MAX_DEPTH=5

# ---------------------------------------------------------------------------
# walk_command <binary> <full_command_path> <depth>
#
# full_command_path is the space-joined path, e.g. "solana" or "solana transfer"
# ---------------------------------------------------------------------------
walk_command() {
  local binary="$1"
  local full_path="$2"
  local depth="$3"

  # Cycle check
  if grep -qxF "$full_path" "$VISITED_FILE" 2>/dev/null; then
    return
  fi
  echo "$full_path" >> "$VISITED_FILE"

  # Depth limit
  if [[ "$depth" -ge "$MAX_DEPTH" ]]; then
    return
  fi

  # Capture --help output (tolerate non-zero exits — some clap binaries exit 1)
  local help_output
  local cmd_name="${full_path%% *}"           # first word = binary name
  local subcmds_str="${full_path#* }"         # everything after first word

  if [[ "$full_path" == "$subcmds_str" ]]; then
    # No subcommand component — invoke as: binary --help
    help_output="$(timeout 10s "$binary" --help 2>&1 || true)"
  else
    # Invoke as: binary <sub1> [<sub2> ...] --help
    read -ra subcmds <<< "$subcmds_str"
    help_output="$(timeout 10s "$binary" "${subcmds[@]}" --help 2>&1 || true)"
  fi

  # Append entry to shared file
  printf '=== %s ===\n%s\n\n' "$full_path" "$help_output" >> "$ENTRIES_FILE"

  # ---------------------------------------------------------------------------
  # Subcommand discovery
  # Handles Clap 3 (SUBCOMMANDS:), Clap 4 (Commands:), and variants.
  # Indented lines after the header that start with a lowercase letter are
  # treated as subcommand names; the first whitespace-delimited token is used.
  # ---------------------------------------------------------------------------
  local in_block=0
  while IFS= read -r line; do
    # Detect subcommand block header (case-insensitive variants)
    if echo "$line" | grep -qE '^\s*(Commands|SUBCOMMANDS?|Available subcommands?)\s*:'; then
      in_block=1
      continue
    fi

    if [[ "$in_block" -eq 1 ]]; then
      # A blank line or an unindented non-empty line ends the block
      if [[ -z "$line" ]] || echo "$line" | grep -qE '^[^ ]'; then
        in_block=0
        continue
      fi

      # Extract the first token from the indented line
      local sub
      sub="$(echo "$line" | awk '{print $1}')"

      # Skip if empty, starts with '-', or is the meta 'help' subcommand
      [[ -z "$sub" ]] && continue
      [[ "$sub" == "help" ]] && continue
      echo "$sub" | grep -qE '^[a-zA-Z]' || continue

      walk_command "$binary" "$full_path $sub" "$((depth + 1))"
    fi
  done <<< "$help_output"
}

# ---------------------------------------------------------------------------
# capture_single <binary> <cmd_name>
# Like walk_command but without recursion (for commands that have no subcommands)
# ---------------------------------------------------------------------------
capture_single() {
  local binary="$1"
  local cmd_name="$2"

  if grep -qxF "$cmd_name" "$VISITED_FILE" 2>/dev/null; then
    return
  fi
  echo "$cmd_name" >> "$VISITED_FILE"

  local help_output
  help_output="$(timeout 10s "$binary" --help 2>&1 || true)"
  printf '=== %s ===\n%s\n\n' "$cmd_name" "$help_output" >> "$ENTRIES_FILE"
}

# ---------------------------------------------------------------------------
# Process each command root
# ---------------------------------------------------------------------------

# Commands with full subcommand recursion
RECURSIVE_COMMANDS=("solana" "agave-validator")

# Commands where only the top-level --help is captured (no subcommands)
SINGLE_COMMANDS=("solana-test-validator" "agave-watchtower")

for cmd in "${RECURSIVE_COMMANDS[@]}"; do
  binary="${BIN_DIR}/${cmd}"
  if [[ -x "$binary" ]]; then
    echo "  Walking subcommands: ${cmd}" >&2
    walk_command "$binary" "$cmd" 0
  else
    echo "  Warning: ${cmd} not found in ${BIN_DIR} — skipping" >&2
    printf '=== %s ===\n[NOT FOUND IN BUILD]\n\n' "$cmd" >> "$ENTRIES_FILE"
  fi
done

for cmd in "${SINGLE_COMMANDS[@]}"; do
  binary="${BIN_DIR}/${cmd}"
  if [[ -x "$binary" ]]; then
    echo "  Capturing: ${cmd}" >&2
    capture_single "$binary" "$cmd"
  else
    echo "  Warning: ${cmd} not found in ${BIN_DIR} — skipping" >&2
    printf '=== %s ===\n[NOT FOUND IN BUILD]\n\n' "$cmd" >> "$ENTRIES_FILE"
  fi
done

# ---------------------------------------------------------------------------
# Write output file: header + alphabetically-sorted entries
# ---------------------------------------------------------------------------

# generated_at is intentionally excluded from the file so that diffs between
# versions reflect only actual CLI changes, not timestamp noise.
{
  printf '# cli-help-dump\n'
  printf '# client: %s\n' "$CLIENT"
  printf '# version: %s\n' "$VERSION"
  printf '# arch: %s\n\n' "$ARCH"
} > "$OUTPUT_FILE"

# Sort blocks alphabetically by command path using Python 3 (available on all GHA runners)
python3 - "$ENTRIES_FILE" "$OUTPUT_FILE" <<'PYEOF'
import sys
import re

entries_file = sys.argv[1]
output_file  = sys.argv[2]

with open(entries_file) as f:
    content = f.read()

# Each entry starts with "=== ".  Prepend a sentinel newline so the split
# pattern works uniformly for the very first block too.
parts = re.split(r'\n(?==== )', '\n' + content)
blocks = [p.strip('\n') for p in parts if p.strip()]

def sort_key(block):
    m = re.match(r'=== (.+?) ===', block)
    return m.group(1) if m else ''

blocks.sort(key=sort_key)

with open(output_file, 'a') as f:
    for block in blocks:
        f.write(block + '\n\n')
PYEOF

line_count="$(wc -l < "$OUTPUT_FILE")"
echo "Wrote ${line_count} lines to ${OUTPUT_FILE}" >&2
