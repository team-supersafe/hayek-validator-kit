#!/usr/bin/env bash
set -euo pipefail

# default user
rm -rf /home/$HOST_DEFAULT_USER/.ssh
mkdir -p /home/$HOST_DEFAULT_USER/.ssh
chmod 700 /home/$HOST_DEFAULT_USER/.ssh

cat /localnet-ssh-keys/${HOST_DEFAULT_USER}_ed25519.pub > /home/${HOST_DEFAULT_USER}/.ssh/authorized_keys

chmod 600 /home/${HOST_DEFAULT_USER}/.ssh/authorized_keys
chown -R ${HOST_DEFAULT_USER}:${HOST_DEFAULT_USER} /home/${HOST_DEFAULT_USER}/.ssh
# end default user

# set RPC_URL globally for all users
if [[ -n "${RPC_URL:-}" ]]; then
  echo "export RPC_URL=$RPC_URL" >> /etc/environment
fi