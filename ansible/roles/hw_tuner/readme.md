# hw_tuner Ansible Role

This Ansible role is responsible for performing hardware performance optimizations specifically tailored for Solana validator nodes.

## Purpose
The `hw_tuner` role applies a set of system-level and hardware-specific tuning parameters to maximize the performance, reliability, and efficiency of Solana validator operations. These optimizations are based on best practices for running high-performance Solana nodes and may include:

- CPU and memory tuning
- Network stack optimizations
- Disk I/O enhancements
- Kernel parameter adjustments
- Disabling unnecessary services
- Applying recommended sysctl settings

## Usage
Include this role in your Ansible playbook for Solana validator deployment or maintenance. Example:

```yaml
- hosts: solana_validators
  roles:
    - hw_tuner
```

## Requirements
- Root or sudo privileges on the target hosts
- Compatible with Linux distributions commonly used for Solana validators (e.g., Ubuntu, Debian, CentOS)

## Variables
You can customize the tuning parameters by overriding role variables in your playbook or inventory. Refer to the `defaults/main.yml` and `vars/main.yml` files for available options.

## Notes
- Always review the changes applied by this role to ensure compatibility with your specific hardware and Solana version.
- Some optimizations may require a system reboot to take effect.

## References
- [Solana Validator Hardware Recommendations](https://docs.solana.com/running-validator/validator-reqs)
- [Solana Performance Tuning Guide](https://docs.solana.com/running-validator/performance-tuning)
