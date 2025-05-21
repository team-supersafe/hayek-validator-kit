# Troubleshooting Agave

See [https://youtu.be/nY2SFjaDXHw?si=Sd-ko1lTmpgkz\_VH\&t=1560](https://youtu.be/nY2SFjaDXHw?si=Sd-ko1lTmpgkz_VH\&t=1560)

### Process running

Verify that the process is running (run on validator machine). In a new terminal window, shh into your server

```bash
ps aux | grep agave-validator
```

You should see a line in the output that includes `agave-validator` with all the flags that were added to your validator.sh script.

### Check the logs

Make sure your validator is producing reasonable log output (run on validator machine). In a new terminal window, ssh into your validator machine, switch users to the `sol` user and tail the logs:

```bash
su - sol
tail -f /home/sol/logs/agave-validator.log
```

### Check version

Check the version you are starting with (run on validator machine). Useful if your validator is in some kind of restart loop

```bash
grep -B1 'Starting validator with' /home/sol/logs/agave-validator.log -A50
```

### Check PoH speed

```bash
grep -B1 'PoH speed check' /home/sol/logs/agave-validator.log
```

[https://discord.com/channels/428295358100013066/1187805174803210341/1346883323020050492](https://discord.com/channels/428295358100013066/1187805174803210341/1346883323020050492) have you tried running on testnet, just to check? cpu may not be fast enough for poh if you grep for poh speed check in the log, post it here. you'll have to add the log to your startup cmd grep 'PoH speed check' log/validator.log

[https://discord.com/channels/428295358100013066/1187805174803210341/1347136943825227776](https://discord.com/channels/428295358100013066/1187805174803210341/1347136943825227776) Backup validator mainnet (EPYC 9254) \[2025-03-05T11:42:00.837392249Z INFO solana\_core::validator] PoH speed check: computed hashes per second 16740697, target hashes per second 10000000

### Check Gossip

Make sure that the validator has registered itself with the gossip network (run anywhere)

```bash
# search validator by keypair and see IP address and RPC ports
# (useful when you want to grab a snapshot from a validator directly)
solana -ut gossip | grep <validator-identity-pubkey> 

# Output example:
# IP Address      | Identity                                     | Gossip | TPU   | TPU-QUIC | RPC Address           | Version | Feature Set
# ----------------+----------------------------------------------+--------+-------+----------+-----------------------+---------+----------------
# 185.209.178.99  | hytUYBP59GaVyiqG2ebrDozwoziVd17V5HYRPHp5R2W  | 8001   | 8003  | 8009     | none                  | 2.1.13  | 1725507508
# 139.178.68.207  | 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on | 8001   | 8004  | 8009     | 139.178.68.207:80     | 1.14.17 | 3488713414
```

### Check voting readyness

Verify that your validator is ready to be a voting participant of the network (run anywhere).

After you have verified that your validator is in gossip, you should stake some SOL to your validator. Once the stake has activated (which happens at the start of the next epoch)

```bash
solana -ut validators

solana -ut validators | head -n 3 # to see column headers
# Identity | Vote Account | Commission | Last Vote | Root Slot | Skip Rate | Credits | Version | Active Stake

solana-keygen pubkey validator-identity-keypair.json # get the validator identity pubkey

# At the begining, when your validator doesn't have any stake yet, you need to add the flag --keep-unstaked-delinquents
solana -ut validators --keep-unstaked-delinquents | grep <validator-identity-pubkey>
# 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on  FX6NNbS5GHc2kuzgTZetup6GZX6ReaWyki8Z8jC7rbNG  100%  197434166 (  0)  197434133 (  0)   2.11%   323614  1.14.17   2450110.588302720 SOL (1.74%)
```

### Check catchup speed

Check catchup speed with `solana catchup` (run on validator machine)

It tells you how far behind the network your validator is and how quickly you are catching up

* If you use `--private-rpc` then you need to pass `--our-localhost` here. See [https://github.com/solana-labs/solana/issues/8407?ref=solana.ghost.io](https://github.com/solana-labs/solana/issues/8407?ref=solana.ghost.io)

```
solana -ut catchup /home/sol/keys-testnet/validator-identity-keypair.json

solana -ut catchup --our-localhost 8899
# ⠄ 77 slot(s) behind (us:320589449 them:320589526), our node is gaining at 6.0 slots/second (AVG: 5.0 slots/second, ETA: slot 320589524 in 

solana -ut catchup --our-localhost 8899
# hytUYBP59GaVyiqG2ebrDozwoziVd17V5HYRPHp5R2W has caught up (us:320587019 them:320587015)
```

### Agave-Monitor

Monitor with `agave-validator monitor` (run on validator machine)

```
agave-validator -l /mnt/ledger/ monitor

# Output if you have firewall issues:
# Ledger location: /mnt/ledger/
# ⠤ Unable to connect to validator: Connection refused (os error 111)                                                                       ⠲ Unable to connect to validator: Connection refused (os error 111)                                                                       ⠴ Unable to connect to validator: Connection refused (os error 111)                                                                       ⠦ Unable to connect to validator: Connection refused (os error 111)                                                                       ⠒ Unable to connect to validator: Connection refused (os error 111)                                                                       ⠄ Unable to connect to validator: Connection refused (os error 111)
```

### Check ports

Check that ports 8801, ... are open after agave-validator is running (run on validator machine)

It can take a few minutes for the process to open ports after the validator started

```
sudo netstat -ntlp # check open ports
```

Check connection is possible from validator machine to the network entry points (run on validator machine)

```
telnet entrypoint.testnet.solana.com 8001
telnet entrypoint2.testnet.solana.com 8001
telnet entrypoint3.testnet.solana.com 8001

nc -vz entrypoint.testnet.solana.com 8001
nc -vz entrypoint2.testnet.solana.com 8001
nc -vz entrypoint3.testnet.solana.com 8001
```

### Check reachability

Check connection is possible from the outside to your validator machine (run anywhere)

```
nc -vz <YOUR_VALIDATOR_HOSTNAME> 8001 # gossip port you use. # this port is only open after the agave-validator is running

nc -vz <YOUR_VALIDATOR_HOSTNAME> 8900 # this port is only open after the agave-validator is running
```

### Check gossip entrypoint

Make sure network entry points resolve to the expected IP addresses (run anywhere). I've seen issues with outdated DNS server on Solana's side:

```
nslookup entrypoint.testnet.solana.com # resolved to 35.203.170.30 at the time of writing
nslookup entrypoint2.testnet.solana.com # resolved to 139.178.94.143 at the time of writing
```

### Check NAT

Check if you are behind a NAT (run on validator machine)

```
sudo apt install inetutils-traceroute
traceroute <YOUR_VALIDATOR_HOSTNAME>
# If you only see one hop, then you are not behind a NAT
# traceroute to 88.20.3.135 (88.20.3.135), 64 hops max
#   1   88.20.3.135  0.510ms  0.357ms  0.293ms
```

### Get snapshot manually

Manually getting snapshot from another validator

* See [https://youtu.be/nY2SFjaDXHw?si=R3VeG1z3NzRyd8RR\&t=4246](https://youtu.be/nY2SFjaDXHw?si=R3VeG1z3NzRyd8RR\&t=4246)

```
# stop the validator service
systemctl stop sol

# get the IP address of the other validator
solana -ut gossip | grep <the_other_validator_identity_pubkey>
# then copy the THE_OTHER_VALIDATOR_IP_ADDRESS:8899 (if using the standard port)

# go to your snapshots dir. this might be the ledger directory (/mnt/ledger) if
# you didn't specified a snapshot path in your startup script
cd /mnt/snapshots

# donload the snapshot
wget --trust-server-names http://THE_OTHER_VALIDATOR_IP_ADDRESS:8899/snapshot.tar.bz
wget --trust-server-names http://THE_OTHER_VALIDATOR_IP_ADDRESS:8899/incremental-snapshot.tar.bz

# restart the sol service
systemctl start sol

# monitor the validator
agave-validator -l /mnt/ledger/ monitor

# check also with catchup, sometimes `monitor` reports more slots behind thant `catchup`
solana -ut catchup /home/sol/keys-testnet/identity.json
```
