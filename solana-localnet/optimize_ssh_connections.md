## SSH Config
1. Edit your SSH config file (usually ~/.ssh/config)
```sh
cat>> ~/.ssh/config <<'EOF'
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 10m
EOF

ControlMaster auto
ControlPath /tmp/ssh_mux_%h_%p_%r
ControlPersist 10m
```
  - ControlMaster auto enables multiplexing.
	- ControlPath specifies the socket file location (h: host, p: port, r: user).
	-	ControlPersist 10m keeps the master connection open for 10 minutes after the last session closes.

2. Create the directory for socket files (if it doesn’t exist)
```sh
mkdir -p ~/.ssh/sockets
chmod 700 ~/.ssh/sockets
```
