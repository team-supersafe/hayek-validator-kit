#!/bin/bash

# schedule_set_hot_spare_identity.sh
#
# This script schedules a validator set-identity operation at a specified UTC date and time.
# The intention is to switch the validator's identity to a non-voting (hot spare) identity,
# placing the main identity in a delinquent state, typically for a planned cluster halt.
#
# Usage:
#   ~/bin/schedule_set_hot_spare_identity.sh "<UTC date and time>"
#
# Example:
#   ~/bin/schedule_set_hot_spare_identity.sh "15:00 UTC 2025-07-02"
#
# The date and time format must be compatible with the 'at' command (see 'man at').

if [ -z "$1" ]; then
  echo "[ERROR] No date/time provided."
  echo "Usage: $0 \"<UTC date and time>\""
  echo "Example: $0 \"15:00 UTC 2025-07-02\""
  exit 1
fi

SCHEDULED_TIME="$1"
IDENTITY_FILE="~/keys/hayek-testnet/hot-spare-identity.json"
LEDGER_PATH="/mnt/ledger"

COMMAND="agave-validator --ledger $LEDGER_PATH set-identity $IDENTITY_FILE"
echo "$COMMAND" | at $SCHEDULED_TIME

if [ $? -eq 0 ]; then
  echo "[INFO] Validator identity switch scheduled at: $SCHEDULED_TIME"
else
  echo "[ERROR] Failed to schedule validator identity switch."
  exit 2
fi
