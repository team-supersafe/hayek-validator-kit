#!/usr/bin/env bash
set -euo pipefail

# Start an ssh-agent inside ansible-control-localnet and load the dev keys.
SOCK="/tmp/ssh-agent.sock"
KNOWN_HOSTS="${HOME}/.ssh/known_hosts"
HOSTS_TO_PIN=(gossip-entrypoint host-alpha host-bravo host-charlie)

# Clean up any stale socket so ssh-agent can start cleanly.
if [ -S "$SOCK" ]; then
  rm -f "$SOCK"
fi

eval "$(ssh-agent -a "$SOCK")"
export SSH_AUTH_SOCK="$SOCK"

ADDED_ANY=0
for key in /localnet-ssh-keys/*_ed25519; do
  if [ -f "$key" ]; then
    ssh-add "$key" >/dev/null
    ADDED_ANY=1
  fi
done

if [ "$ADDED_ANY" -eq 0 ]; then
  echo "No keys found under /localnet-ssh-keys to add to ssh-agent."
else
  echo "ssh-agent started at $SSH_AUTH_SOCK with keys from /localnet-ssh-keys."
fi

# Pin SSH host keys for the localnet nodes so StrictHostKeyChecking can stay on.
mkdir -p "$(dirname "$KNOWN_HOSTS")"
touch "$KNOWN_HOSTS"
chmod 700 "$(dirname "$KNOWN_HOSTS")"
chmod 600 "$KNOWN_HOSTS"

# Remove any stale entries for these hosts to avoid duplicates.
for host in "${HOSTS_TO_PIN[@]}"; do
  ssh-keygen -R "$host" -f "$KNOWN_HOSTS" >/dev/null 2>&1 || true
done

if ssh-keyscan -T 5 "${HOSTS_TO_PIN[@]}" >>"$KNOWN_HOSTS" 2>/dev/null; then
  echo "Pinned SSH host keys for: ${HOSTS_TO_PIN[*]}"
else
  echo "WARNING: Failed to pin SSH host keys for: ${HOSTS_TO_PIN[*]}"
fi
