## Podman Clean Install

### 1. Remove podman VM
```sh
podman machine stop || true
podman machine rm -f
```

### 2. Uninstall podman
```sh
brew uninstall podman-compose --force
brew uninstall podman --force
rm -rf ~/Library/Containers/com.redhat.podman
rm -rf ~/.config/containers
rm -rf ~/.local/share/containers
```

### 3. Install podman (and podman-compose on macOS)
```sh
# install podman
brew install podman

# On macOS, `podman compose` shells out to Docker Compose unless you install the
# python shim. To use native Podman Compose, also install:
brew install podman-compose

# And set the provider so `podman compose` uses the shim instead of Docker Compose:
export PODMAN_COMPOSE_PROVIDER=podman-compose
```

### 4. Create and start podman VM
```sh
podman machine init --cpus 10 --memory 16384 --disk-size 200

# check vm
podman machine inspect

# start vm
podman machine start

# check vm started
podman info
```

### 5. Podman network diagnostic
```sh
podman network ls

podman run --rm busybox nslookup github.com

podman info | grep networkBackend
```

### 6. Configure podman VM for agave validator
```sh
podman machine ssh

# Optimize sysctl knobs
core@localhost:~$ sudo bash -c "cat >/etc/sysctl.d/21-agave-validator.conf <<EOF
# Increase max UDP buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728

# Increase memory mapped files limit
vm.max_map_count = 1000000

# Increase number of allowed open file descriptors
fs.nr_open = 1000000
EOF"
# check
core@localhost:~$ sudo sysctl -p /etc/sysctl.d/21-agave-validator.conf

core@localhost:~$ sudo bash -c "cat >/etc/systemd/system.conf <<EOF
[Manager]
DefaultLimitNOFILE=1000000
DefaultLimitMEMLOCK=2000000000
EOF"
# check
core@localhost:~$ cat /etc/systemd/system.conf

core@localhost:~$ sudo systemctl daemon-reload

core@localhost:~$ sudo bash -c "cat >/etc/security/limits.d/90-solana-nofiles.conf <<EOF
# Increase process file descriptor count limit
* - nofile 1000000
# Increase memory locked limit (kB)
* - memlock 2000000
EOF"
# check
core@localhost:~$ cat /etc/security/limits.d/90-solana-nofiles.conf

core@localhost:~$ exit
```

### 7. Restart podman VM
```sh
podman machine stop
podman machine start
```
