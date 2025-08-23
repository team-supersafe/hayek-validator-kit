#!/bin/bash
# Shared SSH Key Setup Script
# Usage: setup-ssh-keys.sh <username>

set -euo pipefail

USERNAME="${1:-ubuntu}"
SSH_KEYS_DIR="/tmp/team_ssh_public_keys"

# Setup SSH directory
rm -rf "/home/$USERNAME/.ssh"
mkdir -p "/home/$USERNAME/.ssh"
chmod 700 "/home/$USERNAME/.ssh"

# Clear authorized_keys before appending to avoid duplicates
> "/home/$USERNAME/.ssh/authorized_keys"

# Add team keys if present
if [ -d "$SSH_KEYS_DIR" ]; then
  for file in "$SSH_KEYS_DIR"/*; do
    [ -f "$file" ] || continue
    echo "Adding public key from $file"
    cat "$file" >> "/home/$USERNAME/.ssh/authorized_keys"
    echo "" >> "/home/$USERNAME/.ssh/authorized_keys"
  done

  # Deduplicate authorized_keys entries
  TEMP_AUTH_KEYS="/home/$USERNAME/.ssh/authorized_keys.tmp"
  awk '!seen[$0]++' "/home/$USERNAME/.ssh/authorized_keys" > "$TEMP_AUTH_KEYS"
  mv "$TEMP_AUTH_KEYS" "/home/$USERNAME/.ssh/authorized_keys"
fi

chmod 600 "/home/$USERNAME/.ssh/authorized_keys" || true
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"

echo "✅ SSH keys configured for $USERNAME"
