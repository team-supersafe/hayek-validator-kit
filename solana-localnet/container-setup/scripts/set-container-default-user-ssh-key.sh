#!/usr/bin/env bash
set -euo pipefail

user="${HOST_DEFAULT_USER:?must set HOST_DEFAULT_USER}"
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

# set RPC_URL globally for all users
if [[ -n "${RPC_URL:-}" ]]; then
  rpc_url="${RPC_URL}"
  # Basic validation: require http(s) URL, restrict to safe characters
  if [[ "$rpc_url" =~ ^https?://[A-Za-z0-9._:/?&=%-]+$ ]]; then
    printf 'RPC_URL=%s\n' "$rpc_url" >> /etc/environment
  else
    echo "Invalid RPC_URL: '$rpc_url'" >&2
    exit 1
  fi
fi
