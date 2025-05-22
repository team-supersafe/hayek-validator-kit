---
description: Learn how to encrypt sensitive data like passwords, and SSH private keys
---

# Ansible Vault

Ansible Vault is a powerful feature that allows you to encrypt sensitive data — like passwords, API keys and SSH private keys — so you can safely commit them to GitHub while keeping them secure. The Ansible Vault is kept on your [Ansible Control](../hayek-validator-kit/ansible-control.md) and is shared across your playbooks and hosts to:

* Encrypting variables, files, or strings you use across your Ansible Playbooks
* Protecting secrets like validator keypair sets used to setup validators

A full documentation of the Ansible Vault feature is available in [Ansible's official docs](https://docs.ansible.com/ansible/2.9/user_guide/vault.html).

## Useful Commands

<table><thead><tr><th width="208.18359375">Command</th><th>Description</th></tr></thead><tbody><tr><td>ansible-vault view</td><td>Views encrypted content (after entering the password)</td></tr><tr><td>ansible-vault edit</td><td>Opens an editor to modify encrypted files securely</td></tr><tr><td>ansible-vault decrypt</td><td>Converts a file back to plain text</td></tr><tr><td>--ask-vault-pass</td><td>Prompts for a password at runtime</td></tr><tr><td>--vault-password-file</td><td>Reads the vault pass from a secure file</td></tr></tbody></table>

## Vault password

The simplest way to access encrypted assets stored in the Ansible Vault, is by sharing a passwords to each of the vault items. We recommend using a password manager, like [1Password](1password.md),  to manage shared passwords across your team.

## Best Practices

1. Store only what’s necessary in Vault (not full playbooks).
2. Use one vault file per environment or group to avoid the proliferation of vaults everywhere.
3. Rotate and manage vault keys and passwords securely using a well known password manager, like [1Password](1password.md) or [Keeper](keeper.md).
4. Use tools like `ansible-vault rekey` to change passwords without decrypting.

## Store a secret item

Imagine you have an `aws_secret_access_key = "Follow the white rabbit"` that you wish to put in the vault.&#x20;

```yaml
# from your Ansible Control server, create a vault file
ansible-vault create /ansible/vault/group_vars/all/vault.yml
```

You’ll be prompted to enter a vault password (use 1Password here) and then dropped into a text editor, where you'll paste this:

```yaml
aws_secret_access_key = "Follow the white rabbit"
```

Save and exit.&#x20;

At this point your `aws_secret_access_key` is stored as a variable in the `vault.yml` vault, which is shared by all hosts, and safely encrypted using your 1Password password. You can commit this file to GitHub without a problem.

## Using in a playbook or role

Ansible will auto-load group\_vars/all/vault.yml if the host is in the all group — which it always is. YOu can also explicitly include it:

```yaml
vars_files:
  - group_vars/all/vault.yml
```

To use in your playbook simply use the variable name as any other variable:&#x20;

```yaml
- name: Show AWS Secret Key (don't actually do this 😅)
  debug:
    msg: "My AWS key is {{ aws_secret_access_key }}"
```

When running your playbook, speficy the `--ask-vault-pass` to get prompted for the password at runtime:

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

## Change Vault Password

To change the password on your existing Vault file — like group\_vars/all/vault.yml — use the ansible-vault rekey command.

```bash
ansible-vault rekey group_vars/all/vault.yml
```

You’ll be prompted to:

1. Enter the current vault password (to unlock it)
2. Enter the new password
3. Confirm the new password

That’s it! The file is now encrypted with the new password.
