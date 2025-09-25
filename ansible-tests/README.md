# Hayek Validator Kit - Test Runner

## Quick Start

1. **Check current scenario:**
   ```bash
   echo $MOLECULE_SCENARIO
   # or
   scenarios    # List all scenarios with current one marked
   ```

2. **Select scenario (if needed):**
   ```bash
   select       # Interactive scenario picker
   ```

3. **Run tests:**
   ```bash
   help         # Show available commands for current scenario
   run          # Interactive test runner
   ```

## Available Test Scenarios

- **iam_manager_tests** - IAM Manager Testing with CSV configuration
- **common_tests** - Common system and architecture compatibility testing

## Common Commands

### IAM Manager Tests (Default)
```bash
# Full test suite
molecule test -s iam_manager_tests -- -e csv_file=iam_setup.csv

# Setup only
molecule converge -s iam_manager_tests -- -e csv_file=iam_setup.csv

# Verify only
molecule verify -s iam_manager_tests

# Access container
molecule login -s iam_manager_tests

# Cleanup
molecule destroy -s iam_manager_tests
```

### Other Scenarios
```bash
molecule test -s common_tests
```

## Interactive Commands

- `help` - Show available commands
- `scenarios` - List all scenarios
- `select` - Choose scenario interactively
- `run` - Execute tests interactively

## Important Paths

- `/hayek-validator-kit/` - Main project directory
- `/new-metal-box/` - CSV configuration files
- `/hayek-validator-kit/ansible-tests/molecule/` - All test scenarios

## CI/CD Scripts

### Run All Tests
```bash
# Run all scenarios (stops on first failure)
./scripts/run-all-tests.sh

# Run all scenarios (continue on errors)
./scripts/run-all-tests.sh --continue-on-error
```

### Individual Scenario Scripts
```bash
# IAM Manager tests
./scripts/run-iam-manager-tests.sh

# Common tests  
./scripts/run-common-tests.sh
```

### Features
- **Smart parameter handling** - Applies correct parameters per scenario
- **Detailed reporting** - Shows execution times and results summary
- **CI/CD friendly** - Proper exit codes for pipeline integration
- **Error handling** - Continue on error mode for comprehensive testing

## CSV Generation

CSV file: `/new-metal-box/iam_setup.csv`
