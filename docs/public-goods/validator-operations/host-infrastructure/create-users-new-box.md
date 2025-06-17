---
description: Steps to create users on a newly provisioned server
---

# Create Users on a New Server

## Prerequisites

To follow these steps, make sure you have one of the following environments:

1. **Hayek .devcontainer**: This environment comes preconfigured with an `ansible-control` node and all necessary dependencies for management and automation.
2. **Visual Studio Code or Cursor Terminal**: Recommended for working with the devcontainer.
3. **Public SSH key configured on the provisioned server**: Ensure your public SSH key is added to the server you are provisioning. The steps to add your public key may vary depending on your hosting provider.
4. **age encryption tool installed**: This tool must be installed on each operator's workstation, as it will be used to decrypt the password, which will be encrypted using each user's public key. See the [official documentation](https://github.com/FiloSottile/age) for more details.
   - On Ubuntu/Debian: `apt install age`
   - On macOS: `brew install age`
5. **Create the secrets folder**: Create the folder `~/.new-metal-box-secrets` on your workstation. This folder must contain the file `users.csv`, which will hold all the information for the users to be created.

   **Example: users.csv**

   Below is an example of how the `users.csv` file should be structured (replace with your actual user data):

   | user   | email              | sent_email | key                                                                                  | group_a | group_b |
   |--------|--------------------|------------|-------------------------------------------------------------------------------------|---------|---------|
   | alice  | alice@example.com  | TRUE       | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyAlice alice@example.com              | Sol     | Sudo    |
   | bob    | bob@example.com    | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyBob bob@example.com                  | Sol     | Sudo    |
   | carol  | carol@example.com  | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyCarol carol@example.com              | Sol     | Sudo    |
   | dave   | dave@example.com   | FALSE      | ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAExampleKeyDave dave@example.com                | Sol     | Sudo    |

   > **Note:**
   > This CSV solution was implemented to avoid publishing sensitive information in the configuration repository.
   > It is recommended to keep a copy of this file in a secure location where it can be downloaded when needed, such as 1Password, Keeper, or your preferred password manager. This file will **not** contain user passwords.

If you choose **not** to use the devcontainer, you must manually install the following dependencies on your system:

- Ansible
- Python
- passlib

You can install them on Debian/Ubuntu-based systems with the following command:

```sh
sudo apt update && sudo apt install -y ansible python3 python3-pip && pip3 install passlib
```
