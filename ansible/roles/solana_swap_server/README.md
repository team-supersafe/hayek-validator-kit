# Order of operations to perform a validator Identity swap

Validator hosts swap operation happens in `tasks/swap.yml`. Here is a step by step description:

1. **Wait for Restart Window and Unstake Source Validator**
   - First, it waits for a safe restart window on the source validator using `agave-validator wait-for-restart-window`
   - Then it switches the source validator to use its unstaked identity (hot-spare identity)
   - Finally, it updates the identity symlink to point to the unstaked identity
   - This effectively takes the source validator out of active validation

2. **Copy Identity and Vote Account Files**
   - Copies the staked identity file from source to destination
   - Copies the vote account file from source to destination
   - Both operations use rsync to ensure exact file synchronization
   - These files are essential for the destination to take over validation

3. **Transfer Tower File**
   - Gets the tower filename by checking the staked identity's public key
   - Uses rsync to copy the tower file from source to destination
   - The tower file is important for PoH (Proof of History) verification

4. **Promote Destination to Primary Target Validator**
   - Switches the destination validator to use the staked identity
   - Updates the identity symlink on the destination to point to the staked identity
   - This effectively makes the destination validator the new primary validator

In essence, this playbook performs a validator swap operation where:
1. It safely unstakes the source validator
2. Copies all necessary files (identity, vote account, tower) to the destination
3. Promotes the destination validator to take over validation

This is a critical operation that needs to be performed carefully to ensure:
- No downtime in validation
- All necessary files are properly transferred
- The switch happens during a safe restart window
- The correct identities are used at each step

The playbook includes safety checks and uses `ignore_errors` with check mode to allow for dry runs. It also maintains proper file permissions and ownership throughout the process.

## Validations

- The playbook input parameters `source_host`, `destination_host`, `source_validator_name` and `destination_validator_name` are required
  This is to ensure the playbook goal can be achieved during the precheck (`tasks/precheck.yml`)
- Summary of what will happen is presented before executing the swap
- Keys may have the new naming convention or the old naming convention in the swap source host
  Allows for a grace period to support old naming convention in the swap source host (`tasks/prepare.yml`)
- Keys on the swap source host may be different than those on the swap destination host
  (keys will be copied to swap destination host and symlink the primary-target-identity.json to identity.json)
