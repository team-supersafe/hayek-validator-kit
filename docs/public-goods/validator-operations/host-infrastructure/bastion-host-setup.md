# Bastion Host Setup

This documentation describes how to fully configure a **WireGuard VPN Bastion Host** on Ubuntu and allow macOS or Windows clients to connect using their own keys and access the bastion server over SSH only. The VPN is configured to **allow only SSH access to the bastion host (192.168.1.100)** via the tunnel. All other traffic (e.g. web browsing or general internet access) uses the client's normal internet connection.

## Server Setup

### Requirements

The bastion host has very low hardware requirements:

* One virtual CPU (vCPU) setup or better
* 2GB of RAM or more
* 10GB disk or more
* A static IP address
* Ubuntu 24.04 or higher
* Access to a user with sudo access to run the setup and configuration.

### Install WireGuard

First, install WireGuard on the Bastion Host server:

```bash
sudo apt update
sudo apt install wireguard -y
```

#### Generate Server Keys

WireGuard uses **Curve25519** public-key cryptography for authentication. The server needs a private key (kept secret) and a public key (shared with clients).

```bash
umask 077
sudo su
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
```

{% hint style="danger" %}
The private key must remain secret and secure. The public key will be shared with clients to establish the VPN connection.
{% endhint %}

Configure environment variables for these keys. We'll use these later:

```bash
SERVER_PRIVATE_KEY=$(cat /etc/wireguard/server_private.key)
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
echo "Server Public Key: $SERVER_PUBLIC_KEY"
```

Find your main network interface

```bash
ip route show default | awk '/default/ {print $5}'
```

Common interfaces: `eth0`, `ens3`, `enp0s3`, etc. Note this for later use.

### Configure WireGuard

Create the WireGuard config file and make the necessary configurations

```bash
##Create an empty config file
nano /etc/wireguard/wg0.conf
```

Add this config to the newly created config file:

```bash
[Interface]
## The private server IP. Leave as is
Address = 10.10.0.1/24
## WireGuard listening port (51820/udp). Leave as is
ListenPort = 51820
## Replace with the content of  /etc/wireguard/server_private.key
PrivateKey = YOUR_SERVER_PRIVATE_KEY_HERE
## Prevent WireGuard from overwriting this config on changes
SaveConfig = false  

## Firewall rules for SSH-only access
PostUp = bash -c "sysctl -w net.ipv4.ip_forward=1; iptables -I FORWARD -i wg0 -j ACCEPT; iptables -I FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o enp1s0 -j MASQUERADE"
PostDown = bash -c "iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.10.0.0/24 -o enp1s0 -j MASQUERADE"

# === alan ===
[Peer]
## Replace with the client's Workstation WireGuard public key (generated at Alan's Workstation)
PublicKey = YOUR_CLIENT_PUBLIC_KEY_HERE
AllowedIPs = 10.10.0.2/32
```

{% hint style="info" %}
#### Where to get the workstation WireGuard's public key?

Each peer block in the configuration, is the "allow list" for who can connect through the WireGuard tunnel. Each workstation must be configured here, and must also provide its WireGuard Public Key (which is different from the workstation SSH key).&#x20;

Go to [#generate-workstation-keys](bastion-host-setup.md#generate-workstation-keys "mention") to see how to generate this key.
{% endhint %}

#### Enable Forwarding (Required for Routing)

Forwarding must be enabled for the bastion to allow SSH forwarding.

```bash
sudo sed -i '/^net.ipv4.ip_forward/d' /etc/sysctl.conf
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

To verify forwarding status at any time:

```bash
sysctl net.ipv4.ip_forward
```

Expected output:

```bash
net.ipv4.ip_forward = 1
```

#### Configure Firewall (UFW)

Allow WireGuard port:

<pre class="language-bash"><code class="lang-bash"><strong>sudo ufw allow 51820/udp
</strong></code></pre>

Reload UFW

```bash
sudo ufw reload
```

#### Start WireGuard

```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
sudo systemctl status wg-quick@wg0
```

## Client Workstation Setup&#x20;

For clients (or users) connect to the bastion host, they must also have a proper setup, as follows.

### Workstation Install

Download and install WireGuard from the official website:

Visit [https://www.wireguard.com/install/](https://www.wireguard.com/install/) and download the appropriate version for your platform:

* **Windows**: Download the Windows installer
* **macOS**: Download from App Store&#x20;
* **Linux**: Use your distribution's package manager

### Generate Workstation Keys

**For Windows:**

```powershell
# Generate keys
wg genkey | Out-File -FilePath "$env:USERPROFILE\wg_user_private.key" -Encoding ASCII
Get-Content "$env:USERPROFILE\wg_user_private.key" | wg pubkey | Out-File -FilePath "$env:USERPROFILE\wg_user_public.key" -Encoding ASCII
```

**For macOS:**

```bash
# Install WireGuard tools
brew install wireguard-tools  # Ubuntu/Debian

# Generate keys
umask 077
wg genkey | tee ~/wg_user_private.key | wg pubkey > ~/wg_user_public.key
chmod 600 ~/wg_user_private.key
```

**For Linux/Ubuntu:**

```bash
# Install WireGuard tools
sudo apt install wireguard-tools  # Ubuntu/Debian

# Generate keys
umask 077
wg genkey | tee ~/wg_user_private.key | wg pubkey > ~/wg_user_public.key
chmod 600 ~/wg_user_private.key
```

Share the public key content with the system administrator

**macOS/Linux:**

```bash
cat ~/wg_user_public.key
```

**Windows:**

```powershell
Get-Content "$env:USERPROFILE\wg_user_private.key"
```

### Workstation Configuration

In the workstation, the configuration needs to specify which targeted traffic to route through WireGuard, as we don't want all the traffic, but only those targeting the destination servers protected by the Bastion Host.

First, create a new file named `bastion-tunnel.conf`&#x20;

```shellscript
##Create an empty bastion-tunnel config file
nano bastion-tunnel.conf
```

... paste with the following content:

<pre class="language-ini"><code class="lang-ini">[Interface]
## Replace with content of your private key file 
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
## Replace with the workstation's peer IP server config 
Address = 10.10.0.2/24
## Leave as is, or use your custom DNS
<strong>DNS = 1.1.1.1
</strong>
[Peer]
## Replace with the server's public key (provided by admin)
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
## Replace wit the server's public IP; leave the same port
Endpoint = XXX.XXX.XXX.XXX:51820
## Replace with your target server IPs or subnets (e.g., testnet server, mainnet server, etc.)
AllowedIPs = XXX.XXX.XXX.XXX/32,XXX.XXX.XXX.XXX/32,
## Leave as is
PersistentKeepalive = 25
</code></pre>

#### Activate Tunnel on Workstation

Once you have installed the WireGuard client and created the configuration file, you need to import this configuration into the WireGuard app.

**For macOS:**

1. Open WireGuard application
2. Click **Import tunnel from file**
3. Select your configuration file
4. Click **Activate**

**For Windows:**

1. Open WireGuard application
2. Click **Import tunnel(s) from file**
3. Select your configuration file
4. Click **Activate**

## Protecting Target Servers

To restrict SSH access to only the bastion host, configure the firewall on your target servers:

```bash
# Allow SSH only from the bastion host IP
sudo ufw allow from XXX.XXX.XXX.XXX to any port 2522 proto tcp comment "bastion host"

# Deny SSH from all other sources
sudo ufw deny 2522/tcp

# Reload UFW
sudo ufw reload 
```

## Troubleshooting

Server-side checks:

```bash
# Check WireGuard status
sudo wg show

# Check if tunnel is up
ip addr show wg0

# Check firewall rules
sudo ufw status numbered

# Check forwarding
sysctl net.ipv4.ip_forward

# Check WireGuard service
sudo systemctl status wg-quick@wg0
```
