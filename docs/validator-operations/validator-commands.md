---
description: Commonly used validator node CLI commands
---

# Validator Commands

{% code overflow="wrap" %}
```sh
# Check Solana version
solana --version

# Print content of the validator startup script
cat bin/validator-localdemo.sh

# Check if the validator service is running
ps aux | grep validator

# Check in which stage the validator is during the startup process
agave-validator --ledger /mnt/ledger monitor

# Check if our validator node is caught up with the rest of the cluster
# The RPC url ($RPC_URL) is already set as an environment variable pointing to the entrypoint node "http://entrypoint:8899"
solana -u $RPC_URL catchup --our-localhost 8899
```
{% endcode %}
