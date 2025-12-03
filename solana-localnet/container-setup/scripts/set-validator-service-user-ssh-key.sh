#!/usr/bin/env bash
set -euo pipefail

user="${VALIDATOR_SERVICE_USER:?must set VALIDATOR_SERVICE_USER}"
[[ $user =~ ^[a-z_][a-z0-9_-]*$ ]] || { echo "Invalid user: $user" >&2; exit 1; }
passwd_entry="$(getent passwd "$user" || true)"
[[ -n "$passwd_entry" ]] || { echo "Unknown user: $user" >&2; exit 1; }
home_dir="$(cut -d: -f6 <<<"$passwd_entry")"
[[ -n "$home_dir" ]] || { echo "No home directory for user: $user" >&2; exit 1; }

ssh_dir="$home_dir/.ssh"
pub_key_path="/localnet-ssh-keys/${user}_ed25519.pub"
[[ -r "$pub_key_path" ]] || { echo "Missing public key: $pub_key_path" >&2; exit 1; }

rm -rf "$ssh_dir"
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

cat "$pub_key_path" > "$ssh_dir/authorized_keys"
chmod 600 "$ssh_dir/authorized_keys"
chown -R "$user":"$user" "$ssh_dir"
