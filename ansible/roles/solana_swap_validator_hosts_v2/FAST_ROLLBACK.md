# Fast Rollback Procedure for Validator Identity Swap

If the swap process fails after the source validator has been demoted (identity switched to hot-spare), follow these steps to restore the primary identity and resume normal operation:

## 1. Set Keyset Path

```sh
# For mainnet
KEYSET_PATH=/opt/validator/keys/hayek-mainnet
# For testnet
KEYSET_PATH=/opt/validator/keys/hayek-testnet
```

## 2. Restore Symbolic Link

```sh
sudo rm $KEYSET_PATH/identity.json
sudo ln -s $KEYSET_PATH/primary-target-identity.json $KEYSET_PATH/identity.json
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
- **Validator operators must have sudo permission to delete the identity.json file.** The Ansible sudoers template should include a rule like:

    ```text
    %validator_operators ALL=(ALL) NOPASSWD: /usr/bin/rm /opt/validator/keys/*/identity.json
    ```

    (or the appropriate path for your deployment)
