---
description: Description
---

# Validator Setup

Before setting up a validator in a host you need to check that certain requirements are met.

*   Ensure the target host passes the health check by running:\


    ```bash
    bash ~/health_check.sh
    ```
*   Ensure your local computer has a directory called `~/.validator-keys` and that it contains a subdirectory with the name of the keyset to be installed on the target host, this is always the validator name. The following files are required:\


    ```
    primary-target-identity.json
    vote-account.json
    jito-relayer-block-eng.json
    ```

    \
    The setup playbook to install the validator client will check that these files are already present in your local computer on the expected directory and it will fail otherwise.\
    \
    Check that each keypair file is the correct one by verifying its public key with the `solana-keygen pubkey` command
* Ensure that the network cluster delinquency is lower than the requirement set by Solana on the official communication channels before starting the installetion.
