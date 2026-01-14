# Fast Rollback Procedure for Validator Identity Swap

If the swap process fails after the source validator has been demoted (identity switched to hot-spare), follow these steps to restore the primary identity and resume normal operation:

## 1. Set Keyset Path

```sh
KEYSET_PATH=/opt/validator/keys/hayek-mainnet
```

## 2. Restore Symbolic Link

```sh
ln -sf $KEYSET_PATH/primary-target-identity.json $KEYSET_PATH/identity.json
```

## 3. Become the `sol` User

```sh
sudo -u sol -i
```

## 4. Run Set-Identity as `sol`

```sh
agave-validator -l /mnt/ledger set-identity $KEYSET_PATH/identity.json
```

## 5. Monitor your validator to ensure it is running properly

```sh
agave-validator -l /mnt/ledger monitor
```

You should see your primary identity back in play.

**Note:**

- This procedure should be followed immediately if the swap fails after the source validator is demoted, to minimize downtime and risk of delinquency.
- Investigate and resolve the root cause of the swap failure before retrying.
