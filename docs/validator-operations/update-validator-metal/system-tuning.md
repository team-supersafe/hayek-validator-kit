# System Tuning

ssh into your validator

```
export VALIDATOR_HOSTNAME=<YOUR_REMOTE_VALIDATOR_HOSTNAME>
export VALIDATOR_SSH_PORT=<YOUR_REMOTE_VALIDATOR_SSH_PORT>
ssh ubuntu@$VALIDATOR_HOSTNAME -p $VALIDATOR_SSH_PORT
```

1. Optimize sysctl knobs

```
sudo bash -c "cat >/etc/sysctl.d/21-agave-validator.conf <<EOF
# Increase max UDP buffer sizes
net.core.rmem_default = 134217728
net.core.rmem_max = 134217728
net.core.wmem_default = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF"

sudo sysctl -p /etc/sysctl.d/21-agave-validator.conf
```

2. Increase systemd and session file limits (max number of open files) Add `LimitNOFILE=1000000` to the `[Service]` section of your systemd service file, if you use one, otherwise add `DefaultLimitNOFILE=1000000` to the `[Manager]` section of `/etc/systemd/system.conf`.

```
sudo nano /etc/systemd/system.conf
# edit
# check
cat /etc/systemd/system.conf | grep DefaultLimitNOFILE

sudo systemctl daemon-reload
# NOTE for ubuntu 20.04 the above command outputs:
# sudo: setrlimit(RLIMIT_NOFILE): Operation not permitted
# sudo: setrlimit(RLIMIT_NOFILE): Operation not permitted
# So I had to reboot
# sudo reboot
# After rebooting, `sudo systemctl daemon-reload` worked
# NOTE: it took a while (few minutes) to reboot the real remote validator

# On ubuntu 24.04 it worked fine

sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1000000
EOF"

# Check that the change occurred
cat /etc/security/limits.d/90-solana-nofiles.conf
# output
# * - nofile 1000000

### Close all open sessions (log out then, in again) ###
```

3. System Clock Large system clock drift can prevent a node from properly participating in Solana's gossip protocol. Ensure that your system clock is accurate. To check the current system clock, use:

```
timedatectl
#                Local time: Fri 2025-02-21 15:54:37 UTC
#            Universal time: Fri 2025-02-21 15:54:37 UTC
#                  RTC time: Fri 2025-02-21 15:54:38    
#                 Time zone: Etc/UTC (UTC, +0000)       
# System clock synchronized: yes                        
#               NTP service: active                     
#           RTC in local TZ: no
```
