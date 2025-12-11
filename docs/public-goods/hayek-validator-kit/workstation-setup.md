---
description: >-
  Before you can run your Solana Localnet with Hayek Validator Kit, you must
  prepare your local workstation.
---

# Workstation Setup

## Hardware Requirements

To successfully run and manage a Localnet in your workstation, your workstation should be considered a good development machine. That means:

* CPU: Apple Silicon, AMD, Intel Core i5+
* Memory: 16GB+
* OS: Ubuntu 24+, macOS 15+, Windows 10+

## Software Requirements

In addition to having a decent workstation, you must also have installed the following software:

* Docker Desktop 4.54+
* Podman 1.23+
* VSCode or Cursor

## Ansible User Config

Depending on your preferred use of ZSH or BASH on your host, you will need the following environment config file:

```bash
# for zsh
cat ~/.zshenv 

# for bash
cat ~/.bashrc
```

... and check that it looks like this:

{% code overflow="wrap" %}
```bash
. "$HOME/.cargo/env"
export ANSIBLE_REMOTE_USER=michel
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
```
{% endcode %}

If it doesn't exist or it doesn't look like this, you'll need to setup the default Ansible user as an environment variable. This user will be the one connecting to the [Ansible Control](ansible-control.md) node and used to run all Ansible commands. Replace `<your_ansible_user>` with your actual Ansible user from the [server-setup provisioned users](https://github.com/team-supersafe/hayek-validator-kit/tree/main/ansible/iam/users).

Depending on what your host shell is, run:

```bash
# For zsh (used in recent versions of macOS)
echo 'export ANSIBLE_REMOTE_USER=<your_ansible_user>' >> ~/.zshenv

# For bash
echo 'export ANSIBLE_REMOTE_USER=<your_ansible_user>' >> ~/.bashrc
```

After you complete your Ansible user setup, please check again using the previous commands.

## SSH Access

You will need an ssh key to ssh into the nodes on Localnet. The recommended approach is that you create and manage your keys directly on 1Password, Keeper or similar password managers.

### SSH key in 1Password

If you have your ssh key stored in 1Password, run the line corresponding to your preferred host shell:

```sh
# For zsh
echo 'export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"' >> ~/.zshenv

# For bash
echo 'export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"' >> ~/.bashrc
```

### SSH key stored locally

If you have your ssh key already stored locally in your host machine, run the line corresponding to your preferred host shell:

```bash
# For ED25519 keys
ssh-add ~/.ssh/id_ed25519

# For RSA keys
ssh-add ~/.ssh/id_rsa
```

### No SSH Keys

If you don't have an ssh key and you don't want to use 1Password, then you must generate a new keypair for ssh access like this:

```bash
ssh-keygen -t ed25519
# output will go to ~/.ssh/id_ed25519 and ~/.ssh/id_ed25519.pub

cat ~/.ssh/id_ed25519.pub # print the public key to the console
# copy the public key to paste later on the remote validator machine
```

## Environment Checkup

Fully close and reopen your terminal. Yes, do it. Yes. Do. It. Please.

If you are working through your IDE (VS Code or Cursor), fully close and reopen your IDE (not just the project) and check the following:

* Running `echo $ANSIBLE_REMOTE_USER` in your IDE terminal prints your ansible user
* Running `echo $SSH_AUTH_SOCK` in your IDE terminal prints:
  * When not using ssh key stored in 1Password, you should see something like `/private/tmp/com.apple.launchd.MPKIACDzzx/Listeners`
  * When using ssh key stored in 1Password, you should see something like `/Users/<your_user>/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`

You should now be ready to start the cluster.
