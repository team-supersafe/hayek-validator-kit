# Fast Rollback Procedure for Validator Identity Swap

If the swap process fails after the source validator has been demoted (identity switched to hot-spare), follow these steps to restore the primary identity and resume normal operation:

## 1. Set Keyset Path

```sh
# For mainnet
KEYSET_PATH=/opt/validator/keys/hayek-mainnet
# For testnet
KEYSET_PATH=/opt/validator/keys/hayek-testnet
```

## 2. Become the `sol` User

```sh
sudo -u sol -i
```

## 3. Restore the Primary Identity

```sh
agave-validator -l /mnt/ledger set-identity $KEYSET_PATH/primary-target-identity.json
```

## 4. Monitor your validator to ensure it is running properly

```sh
agave-validator -l /mnt/ledger monitor
```

You should see your primary identity back in play.

**Note:**

- This procedure should be followed immediately if the swap fails after the source validator is demoted, to minimize downtime and risk of delinquency.
- Investigate and resolve the root cause of the swap failure before retrying.
- No `identity.json` symlink maintenance is required; rollback uses the explicit `primary-target-identity.json` keypair directly.
