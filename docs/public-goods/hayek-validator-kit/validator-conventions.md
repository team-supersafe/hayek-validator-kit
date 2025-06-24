# Validator Conventions

The Hayek Validator Kit focuses on provisioning validators that follow best practices and certain conventions regarding security practices, internal folder structure, etc.

## File System

### System Units

```
THE UBUNTU HOST METAL/MACHINE

root/
│
├─ etc/           
│  └─ systemd/  
│  │  └─ system/
│  │  │  └─ sol.service    # Defines how the Solana client should start/stop/restart on this host                                 
├─ mnt/                # The mount points on the host
│  └─ accounts/            # Storage for the full Solana accounts db
│  └─ ledger/              # Storage for the full Solana ledger
│  └─ snapshots/           # Storage for snapshot archives of network state
├─ home
│  └─ sol                  # The home of the user 'sol' 
│  └─ alice                # The home of the user 'alice' 
│  └─ bob                  # The home of the user 'bob' 
```

### The 'sol' user home

The 'sol' user is present on every validator provisioned by the Hayek Validator Kit. There are additional configuration files as shown below under the `sol` user home folder:

```
THE 'sol' USER HOME FOLDER

home/sol/
│
├─ bin/                        # Binaries and scripts used on the host
│  └─ run-canopy.sh               # Starts validator-a with its related key set
│  └─ run-sprout.sh               # Starts validator-b with...
│  └─ run-alice_validator.sh      # Sta... 
│  └─ run-jito-relayer.sh         # Starts a co-hosted jito-relayer with its keys
├─ keys/                        # The key store of a host
│  └─ canopy/                     # The key set for a validator named "canopy" 
│  │  └─ identity.json (lnk)           # A link to the active identity of this validator
│  │  └─ staked-identity.json          # A validator identity with active stake
│  │  └─ unstaked-identity.json        # A validator identity without active stake
│  │  └─ jito-relayer-block-eng.json   # For block engine authentication
│  │  └─ jito-relayer-comms-pvt.pem    # Private key for relayer comms handshake
│  │  └─ jito-relayer-comms-pub.pem    # Public key for relayer comms handshake
│  └─ sprout/                   # The key set for a validator named "sprout" 
│  │  └─ [same as above]
│  └─ alice_validator/          # The key set for a validator named "alice_validator" 
│  │  └─ [same as above]
├─ logs/                           # The log dump root folder
│  └─ agave-validator.log
```

Important notes on this structure:

1. The same HOST metal box, can be running different validators (a, b, c, etc.) at different times
2. The same HOST can only be running ONE validator at any moment.
3. At any time the configuration files present in a HOST should be limited to those corresponding to the running validator at that time. That is:
   1. If Host-A is running Validator-X, then only the files, keys and config for Validator-X should be present in Host-A, and no other.
   2. If Validator-X is moved from Host-A to Host-B, Host-A should end up with none of Validator-X's files from its file system, and Host-B should end up with only Validator-X files in its file system.

## Cities and Countries

By convention, we are using 3-letter [IATA Airport Codes](https://en.wikipedia.org/wiki/IATA_airport_code) to refer to cities in file names, city codes, and other code-level variable names. &#x20;

## Services

???
