# GitHub Repo

All the configurations related to the Hayek Validator Kit are [in this GitHub repo](https://github.com/team-supersafe/hayek-sol-validator.git), which you will have to clone locally:&#x20;

```bash
git clone https://github.com/team-supersafe/hayek-validator-kit.git
```

You should get familiar with the contents of the repo. The Localnet cluster is defined in the `Dockerfile` under the `solana-localnet` folder.

## Navigating the repo

The repo structure is intended to be self explanatory. It should resemble this structure, but with actual validator roles and hosts:

```
HAYEK SOLANA VALIDATOR KIT REPO
│
├── ansible/
│   └── ansible.cfg        #the base config file for ansible
│   └── hosts.yml          #the list of hosts and their defined groupings
│   └── group_vars/        #store group specific variables
│   │  └── all.yml
│   │  └── group_a.yml
│   │  └── group_b.yml
│   └── host_vars/         #store host specific variables
│   │  └── host_a.yml
│   │  └── host_b.yml
│   │  └── host_c.yml
│   └── playbooks/         #store playbooks that run orchestrated workloads on hosts
│   │  └── pb_install_rust.yml     
│   │  └── pb_install_solana_cli.yml 
│   │  └── pb_setup_validator_jito.yml   
│   │  └── pb_change_validator_hw.yml      
│   └── roles/             #store host roles and their associated tasks and vars
│   │  └── carpenter/
│   │  └── plumber/
│   │  └── painter/
│   │  └── web_server/
│   │  └── db_server/
│   │  └── validator/
│   └──  vault/            #store sensitive variables that require encryption
│
├── solana-localnet/       #where all the solana-localnet is configued
│   └── build-cli/         #builds and run the solana cli in localnet 
```
