# Validator Conventions

The Hayek Validator Kit focuses on provisioning validators that follow best practices and certain conventions regarding security practices, internal folder structure, etc.

In general, validators will have the following key directories and files:

```
A VALIDATOR (MANAGED BY HAYEK VALIDATOR KIT)
~
│
├─ folder/
├─ keys/                           # where all the solana-localnet is configued
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

