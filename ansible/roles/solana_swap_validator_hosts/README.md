# Order of operations to perform a validator Identity swap

Validator host swap operation happens in `tasks/swap.yml`. Here is a step by step description:

1. **Wait for Restart Window and Unstake Source Validator**
   - First, it waits for a safe restart window on the source validator using `agave-validator wait-for-restart-window`
   - Then it switches the source validator to use its hot-spare identity
   - Finally, it updates the identity symlink to point to the hot-spare identity
   - This effectively takes the source validator out of active voting

2. **Transfer Tower File**
   - Gets the tower filename by checking the primary target identity's public key
   - Uses rsync to copy the tower file from source to destination
   - The tower file is important for PoH (Proof of History) verification

3. **Promote Destination to Primary Target Validator**
   - Switches the destination validator to use the primary target identity
   - Updates the identity symlink on the destination to point to the primary target identity
   - This effectively makes the destination validator the new primary validator

## Validations

- The playbook input parameters `source_host`, `destination_host`, `source_validator_name` and `destination_validator_name` are required. This is enforced during the precheck (`tasks/precheck.yml`) to ensure that the playbook goal can be achieved.
- Summary of what will happen is presented before executing the swap
- Keys may have the new naming convention or the old naming convention in the swap source host
  Allows for a grace period to support old naming convention in the swap source host (`tasks/prepare.yml`)
- Keys on the swap source host may be different than those on the swap destination host
  The playbook enforces that both validator hosts contain the same key set to avoid spinning a different validator identity
