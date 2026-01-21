# Bastion Host Setup

This documentation describes how to fully configure a **WireGuard VPN Bastion Host** on Ubuntu and allow macOS or Windows clients to connect using their own keys and access the bastion server over SSH only. The VPN is configured to **allow only SSH access to the bastion host (192.168.1.100)** via the tunnel. All other traffic (e.g. web browsing or general internet access) uses the client's normal internet connection.

```
Server: Ubuntu Bastion Host (192.168.1.100)
```

## Server Setup

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
Address = 10.10.0.1/24
ListenPort = 51820
PrivateKey = YOUR_SERVER_PRIVATE_KEY_HERE
SaveConfig = false  # Prevent WireGuard from overwriting this config on changes

PostUp = bash -c "sysctl -w net.ipv4.ip_forward=1; iptables -I FORWARD -i wg0 -j ACCEPT; iptables -I FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o enp1s0 -j MASQUERADE"
PostDown = bash -c "iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT; iptables -t nat -D POSTROUTING -s 10.10.0.0/24 -o enp1s0 -j MASQUERADE"

# === alan ===
[Peer]
PublicKey = YOUR_CLIENT_PUBLIC_KEY_HERE
AllowedIPs = 10.10.0.2/32
```

#### Configuration Breakdown:

> * `Address`: VPN IP of the bastion server (10.10.0.1/24)
> * `ListenPort`: WireGuard listening port (51820/udp)
> * `PrivateKey`: Server's private key (replace with actual key)
> * `SaveConfig = false`: Prevents automatic config changes
> * `PostUp/PostDown`: Firewall rules for SSH-only access
> * `PublicKey`: Client's public key (replace with actual key)
> * `AllowedIPs`: Client's VPN IP range (10.10.0.2/32)

> Replace `YOUR_SERVER_PRIVATE_KEY_HERE` with the content of  `/etc/wireguard/server_private.key` \
> Replace `YOUR_CLIENT_PUBLIC_KEY_HERE` with the client's public key (will be provided by Alan)

#### Enable Forwarding (Required for Routing)

{% hint style="info" %}
This must remain enabled for the bastion to allow SSH forwarding.
{% endhint %}

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
* **macOS**: Download from App Store and install Wireguard tools via Homebrew\
  &#xNAN;**`brew install wireguard-tools`**
* **Linux**: Use your distribution's package manager

### Generate Workstation Keys

**For Windows:**

```powershell
# Generate keys
wg genkey | Out-File -FilePath "$env:USERPROFILE\wg_user_private.key" -Encoding ASCII
Get-Content "$env:USERPROFILE\wg_user_private.key" | wg pubkey | Out-File -FilePath "$env:USERPROFILE\wg_user_public.key" -Encoding ASCII
```

**For macOS/Ubuntu:**

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

In the workstation, the configuration needs to specify which targeted traffic to route through WireGuard, as we don't want all the traffic, but only those targetting the destination servers protected by the Bastion Host.

First, create a new file named `bastion-tunnel.conf` with the following content:

```ini
[Interface]
## Replace with content of your private key file 
PrivateKey = YOUR_CLIENT_PRIVATE_KEY_HERE
Address = 10.10.0.2/24
DNS = 1.1.1.1

[Peer]
## Replace with the server's public key (provided by admin)
PublicKey = YOUR_SERVER_PUBLIC_KEY_HERE
Endpoint = 192.168.1.100:51820
## Replace with your target server IPs (e.g., testnet server, mainnet server, etc.)
AllowedIPs = 192.168.1.200/32,192.168.1.210/32,
PersistentKeepalive = 25
```

{% hint style="info" %}
Replace `YOUR_CLIENT_PRIVATE_KEY_HERE` with content of your private key file  \
Replace `YOUR_SERVER_PUBLIC_KEY_HERE` with the server's public key (provided by admin)\
**AllowedIPs**: Replace `192.168.1.200/32` with your target server IP (e.g., testnet server, mainnet server, etc.)&#x20;
{% endhint %}

#### Import and Activate Tunnel

Once you have installed the WireGuard client and created the configuration file, you need to import this configuration into the WireGuard application.

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

### Firewall Configuration for Target Servers

To restrict SSH access to only the bastion host, configure the firewall on your target servers:

```bash
# Allow SSH only from the bastion host IP
sudo ufw allow from 192.168.1.100 to any port 2522 proto tcp

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
