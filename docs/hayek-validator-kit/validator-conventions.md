# Validator Conventions

The Hayek Validator Kit focuses on provisioning validators that follow best practices and certain conventions regarding security practices, internal folder structure, etc.

In general, validators will have the following key directories and files:

```
A VALIDATOR (MANAGED BY HAYEK VALIDATOR KIT)
~
│
├─ bin/                            # Binaries and scripts used on the host
│  └─ run-validator-a.sh             # Starts validator-a with its related key set
│  └─ run-validator-b.sh             # Starts validator-b with...
│  └─ run-validator-c.sh             # Sta... 
├─ keys/                           # The key store of a host
│  └─ validator-a/                   # The key set for validator a 
│  │  └─ identity.json (lnk)           # A link to the active identity of this validator
│  │  └─ staked-identity.json          # A validator identity with active stake
│  │  └─ unstaked-identity.json        # A validator identity without active stake
│  │  └─ jito-relayer-block-eng.json   # For block engine authentication
│  │  └─ jito-relayer-comms-pvt.pem    # Private key for relayer comms handshake
│  │  └─ jito-relayer-comms-pub.pem    # Public key for relayer comms handshake
│  └─ validator-b/                  
│  │  └─ [same as validator-a]
```

Important notes on this structure:

1. The same HOST metal box, can be running different validators (a, b, c, etc.) at different times
2. The same HOST can only be running ONE validator at any moment.
3. At any time the configuration files present in a HOST should be limited to those corresponding to  the running validator at that time. That is:
   1. If Host-A is running Validator-X, then only the files, keys and config for Validator-X should be present in Host-A, and no other.
   2. If Validator-X is moved from Host-A to Host-B, Host-A should end up with none of Validator-X's files from its file system, and Host-B should end up with only Validator-X files in its file system.
