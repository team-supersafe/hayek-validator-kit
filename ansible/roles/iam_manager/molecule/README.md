# Molecule Testing for iam_manager

## Overview

This Molecule configuration tests the `iam_manager` role using **real CSV files** from the `~/new-metal-box/` directory, eliminating hardcoded test data and ensuring tests reflect actual production usage patterns.

## Key Features

✅ **No Hardcoded Data**: Reads real CSV files dynamically  
✅ **Production Pattern**: Uses same `csv_file` variable as production playbooks  
✅ **Flexible CSV Selection**: Specify any CSV file via command line  
✅ **Idempotent Testing**: Supports re-running tests without conflicts  
✅ **Realistic Coverage**: Tests with actual user/group/SSH key combinations  

## Usage

### Basic Test (uses default CSV)
```bash
cd ansible/roles/iam_manager
molecule test -s default
```

### Test with Specific CSV File
```bash
cd ansible/roles/iam_manager
molecule test -s default -- -e "csv_file=iam_setup.csv"
```

### Test Individual Phases
```bash
# Create and converge only
molecule converge -s default -- -e "csv_file=users2.csv"

# Run verification only
molecule verify -s default

# Test idempotence
molecule idempotence -s default
```

## Available CSV Files

Check available CSV files in the source directory:
```bash
ls ~/new-metal-box/*.csv
```

Common test files:
- `iam_setup.csv` - Complete role coverage with all user types
- `users2.csv` - Multi-group user scenarios  
- `users3.csv` - Basic user configurations

## CSV Structure

All CSV files must follow this exact format:
```csv
user,key,group_a,group_b,group_c,group_d
username,"ssh-ed25519 AAAAC3... email@domain.com",primary_group,secondary_group,tertiary_group,quaternary_group
```

## Test Scenarios Covered

### User Types Tested
- **🔧 Sysadmin Users**: Full system access + password self-service
- **🤖 Ansible Executor**: Automation access + sudo privileges  
- **⚙️ Validator Operators**: Service management permissions
- **👀 Validator Viewers**: Read-only monitoring access
- **🔒 Multi-Group Users**: Users with multiple group memberships

### Security Validations
- SSH key format validation (ed25519/RSA)
- RSA key length enforcement (≥2048 bits)
- Sudo permission verification
- RBAC group isolation testing
- User privilege escalation prevention

## Configuration Variables

### Default Values
```yaml
molecule_csv_file: "{{ csv_file | default('molecule_test_users.csv') }}"
molecule_csv_source_dir: "{{ csv_source_dir | default('~/new-metal-box') }}"
molecule_csv_dir: "/tmp/molecule"
molecule_testing: true  # Enables idempotent testing
```

### Override Options
```bash
# Use different source directory
molecule test -- -e "csv_source_dir=/path/to/csv/files"

# Use specific CSV file
molecule test -- -e "csv_file=custom_users.csv"

# Combine both
molecule test -- -e "csv_source_dir=/custom/path" -e "csv_file=test.csv"
```

## Troubleshooting

### CSV File Not Found
```
FAILED! => {"msg": "CSV file test.csv not found in ~/new-metal-box"}
```
**Solution**: Check file exists and path is correct
```bash
ls ~/new-metal-box/test.csv
```

### Permission Denied
```
FAILED! => {"msg": "Permission denied: ~/new-metal-box/users.csv"}
```
**Solution**: Ensure file is readable
```bash
chmod 644 ~/new-metal-box/users.csv
```

### Template Recursion Error
```
FAILED! => {"msg": "Recursive loop detected in template"}
```
**Solution**: Variable name conflict - use `molecule_` prefixed variables

## Migration from Hardcoded Tests

### Before (Hardcoded)
```yaml
content: |
  user,key,group_a,group_b,group_c,group_d
  testuser1,"ssh-ed25519 AAAAC3...",sysadmin,,,
```

### After (Dynamic)
```yaml
- name: Copy real CSV file to molecule directory
  ansible.builtin.copy:
    src: "{{ molecule_csv_source_dir }}/{{ molecule_csv_file }}"
    dest: "{{ molecule_csv_dir }}/{{ molecule_csv_file }}"
```

## Container Lifecycle Management

### Default Behavior
- **`molecule converge`** → Container remains running for debugging
- **`molecule test`** → Container is automatically destroyed after testing

### Lifecycle Commands
```bash
# Create container only
molecule create

# Configure container (keeps running)
molecule converge -- -e "csv_file=iam_setup.csv"

# Run verification tests
molecule verify

# Manually destroy container
molecule destroy

# Full test cycle (auto-cleanup)
molecule test -- -e "csv_file=iam_setup.csv"
```

### Check Container Status
```bash
# List molecule instances
molecule list

# Check running Docker containers
docker ps | grep molecule
```

### Development Workflow
1. **Development/Debugging**: Use `molecule converge` to keep container active
2. **Interactive Access**: Use `molecule login` to access running container
3. **Manual Cleanup**: Use `molecule destroy` when finished
4. **CI/Testing**: Use `molecule test` for complete cycle with auto-cleanup

### When to Use Each Command

| Command | Use Case | Container Cleanup |
|---------|----------|-------------------|
| `molecule converge` | Development, debugging, iterative testing | ❌ Manual cleanup required |
| `molecule test` | CI/CD, complete validation | ✅ Automatic cleanup |
| `molecule destroy` | Manual cleanup, reset state | ✅ Immediate cleanup |

## Benefits

1. **Realistic Testing**: Uses actual production data patterns
2. **Reduced Maintenance**: No hardcoded test data to maintain
3. **Better Coverage**: Tests real user/group combinations
4. **Consistency**: Same CSV validation as production
5. **Flexibility**: Easy to test different scenarios by switching CSV files
6. **Persistent Debugging**: Container lifecycle control for thorough testing
