#!/bin/bash

# : ${1?"Requires KEYS_DIR"}
# KEYS_DIR=$1

HERE="$(dirname "$0")"
readlink_cmd="readlink"
echo "OSTYPE IS: $OSTYPE"
if [[ $OSTYPE == darwin* ]]; then
  # Mac OS X's version of `readlink` does not support the -f option,
  # But `greadlink` does, which you can get with `brew install coreutils`
  readlink_cmd="greadlink"

  if ! command -v ${readlink_cmd} &> /dev/null
  then
    echo "${readlink_cmd} could not be found. You may need to install coreutils: \`brew install coreutils\`"
    exit 1
  fi
fi

SCRIPT_DIR="$("${readlink_cmd}" -f "${HERE}")"

KEYS_DIR=$(pwd)

if [ ! -d "$KEYS_DIR" ]; then
  echo "Directory $KEYS_DIR does not exist."
  exit 1
fi

VALIDATOR_NAME_AND_CLUSTER_ENVIRONMENT=$(basename "$KEYS_DIR")


arrIN=(${VALIDATOR_NAME_AND_CLUSTER_ENVIRONMENT//-/ })
VALIDATOR_NAME=${arrIN[0]}
CLUSTER=${arrIN[1]}
if [[ $CLUSTER == mainnet* ]]; then CLUSTER="mainnet-beta"; fi

# staked-identity
if [ ! -f "$KEYS_DIR/staked-identity.json" ]; then
  echo "File $KEYS_DIR/staked-identity.json.json does not exist."
  exit 1
fi
IDENTITY_PUBKEY=$(solana-keygen pubkey "$KEYS_DIR/staked-identity.json")
if [ $? -ne 0 ]; then
  echo "Failed to get public key from $KEYS_DIR/staked-identity.json."
  exit 1
fi

# vote-account
if [ ! -f "$KEYS_DIR/vote-account.json" ]; then
  echo "File $KEYS_DIR/vote-account.json does not exist."
  exit 1
fi
VOTE_PUBKEY=$(solana-keygen pubkey "$KEYS_DIR/vote-account.json")
if [ $? -ne 0 ]; then
  echo "Failed to get public key from $KEYS_DIR/vote-account.json."
  exit 1
fi

RPC_URL=
case $CLUSTER in

  localcluster)
    RPC_URL="http://localhost:8899"
    ;;

  testnet)
    RPC_URL="https://api.testnet.solana.com"
    ;;

  mainnet-beta)
    RPC_URL="https://api.mainnet-beta.solana.com"
    ;;

  *)
    echo -n "Unknown cluster: $CLUSTER"
    exit 1
    ;;
esac

# alias solana="solana -u $RPC_URL"

solana () {
  command solana -u $RPC_URL "$@"
}

echo "validator: $VALIDATOR_NAME"
echo "cluster: $CLUSTER"
echo "rpc url: $RPC_URL"
echo "staked-identity: $IDENTITY_PUBKEY"
echo "vote-account: $VOTE_PUBKEY"
echo

solana epoch-info

print_separator() {
    echo
    echo "$1 **************************************************************************************************************************************************"
    echo
}


print_separator "CLI GOSSIP"
solana gossip --output json | jq ".[] | select(.identityPubkey == \"$IDENTITY_PUBKEY\")"


print_separator "CLI VALIDATORS"
solana validators --keep-unstaked-delinquents --output json | jq ".validators | .[] | select(.identityPubkey == \"$IDENTITY_PUBKEY\")"


print_separator "RPC getClusterNodes"
curl -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1, "method":"getClusterNodes"}' \
    $RPC_URL | jq ".result | .[] | select(.pubkey == \"$IDENTITY_PUBKEY\")"


print_separator "BALANCE"
echo "IDENTITY: $(solana balance $IDENTITY_PUBKEY)" # --lamports
echo "VOTE ACCOUNT: $(solana balance $VOTE_PUBKEY)" # --lamports


print_separator "RPC getVoteAccounts"
curl -X POST -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1, \"method\":\"getVoteAccounts\",\"params\":[{\"votePubkey\": \"$VOTE_PUBKEY\"}] }" \
    $RPC_URL | jq


print_separator "CLI stakes - with rewards"
solana stakes $IDENTITY_PUBKEY -v

print_separator "CLI vote-account"
solana vote-account --with-rewards $VOTE_PUBKEY --num-rewards-epochs 5


print_separator "Voting activity"
curl -X POST -H "Content-Type: application/json" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":1, \"method\":\"getVoteAccounts\",\"params\":[{\"votePubkey\": \"$VOTE_PUBKEY\"}] }" \
    $RPC_URL | jq


print_separator "Leader schedule"
solana leader-schedule | grep $IDENTITY_PUBKEY


print_separator "Validator idle time"
$SCRIPT_DIR/validator-idle-time.sh -u $RPC_URL $IDENTITY_PUBKEY 0.47
