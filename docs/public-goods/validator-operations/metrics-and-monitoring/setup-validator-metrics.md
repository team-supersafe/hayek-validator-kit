# Setup Validator Metrics

For monitoring our validator, we use **Telegraf**, a lightweight metrics collection agent. It runs directly on the validator nodes and gathers various hardware metrics such as:

* CPU performance
* NVMe health and usage
* Network traffic
* RAM usage

For validator-specific metrics (such as block production, vote credits, identity balance, etc.), we rely on the **Stakeconomy scripts**. All collected metrics are sent to an external time-series database powered by **InfluxDB**.

## Validator Alerts

We use **Watchtower** for monitoring the validator's health across the Solana cluster. Watchtower runs on a separate machine and continuously checks validator status. If it detects any issues (delinquency, low balance), it sends alerts through multiple channels such as:

* Telegraf
* Discord

## Hardware Alerts

For hardware-related alerts, we rely on **Grafana Alerts**. These are configured to notify us when metrics exceed defined thresholds, including:

* High CPU usage
* High memory usage
* NVMe disks reaching critical usage levels

This setup ensures both the performance and reliability of our validator are actively monitored and issues are promptly addressed.

### Setup Grafana

You can install it yourself or you can use a provider template such as _**Vultr**_, which is easy by _**selecting the server, operating system and at the marketplace center find Grafana**_.\
If you prefer to install Grafana you can use the official guide at\
https://grafana.com/docs/grafana/latest/setup-grafana/installation/\
else you can use Grafana Cloud if you don't want to pay for a private server, you have to be aware Grafana Cloud has some retention metrics limitations\
https://grafana.com/docs/grafana-cloud/

Once your Grafana is running you need to open port 3000 in your firewall

UFW

```bash
ufw allow 3000/tcp
ufw reload
```

Else for proper monitoring system you need to add an SSL certificate to your Grafana Server

You can use an auto-signed certificate or much better you can use a free certificate through Let's Encrypt

### Enable SSL

Install Certbot

```bash
apt install certbot
```

_**For NGINX**_

```bash
apt install python3-certbot-nginx
```

Get Certificate

```bash
certbot --nginx -d your-domain.com -d www.yourdomain.com --email your@email.com --agree-tos --no-eff-email
```

_**For Apache**_

```bash
apt install python3-certbot-apache
```

Get Certificate

```bash
certbot --apache -d your-domain.com -d www.yourdomain.com --email your@email.com --agree-tos --no-eff-email
```

After getting the certificates you need to add them to Grafana, you must go to Grafana folder configuration and add the certificates path

```bash
nano /etc/grafana/grafana.ini
## locate the certificates lines and add / edit the Let's Encrypt certificates
cert_file = /etc/letsencrypt/live/yourdomain.com/fullchain.pem
cert_key = /etc/letsencrypt/live/yourdomain.com/privkey.pem
```

You need to make sure the Grafana user has the read privileges over these files, for that identify which user Grafana is using for running the systemd service

```bash
systemctl show grafana-server -p User
###output message
#User=grafana
```

You need to grant read privileges for that user for certificates

```bash
chmod root:grafana /etc/letsencrypt/live/yourdomain.com/{fullchain.pem,privkey.pem}
chmod 640 root:grafana /etc/letsencrypt/live/yourdomain.com/{fullchain.pem,privkey.pem}
```

Restart Grafana Service

```bash
systemctl restart grafana-server
```

Check your Grafana\
https://yourdomain.com:3000

If you install Grafana through provider templates such as Vultr they will provide you the credentials.

If you used the self installation see the Grafana docs link above.

## Setup InfluxDB

InfluxDB will receive metrics from the Telegraf agent installed on the validator servers as well as from other sources.

### Installation

For DEB-based platforms (e.g. Ubuntu, Debian), add the InfluxData repository with the following commands:

```bash
wget -q https://repos.influxdata.com/influxdata-archive_compat.key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg > /dev/null
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
```

Update package lists and install InfluxDB:

```bash
sudo apt-get update
sudo apt-get install influxdb -y
```

Start InfluxDB and enable it to run at system startup:

```bash
sudo systemctl enable influxdb
sudo systemctl start influxdb
```

### Access to InfluxDB

Connect to the InfluxDB shell:

```bash
influx
```

Or, if you need to connect with SSL (for self-signed or invalid certificates):

```bash
influx -ssl -unsafeSsl
```

#### Create Databases

Our setup includes three main databases:

1. **Validator Metrics Database**: Receives metrics from Telegraf agents installed on validator servers.
2. **Monitoring Box Metrics Database**: Collects metrics from a separate monitoring system.
3. **Solana Block Production Database**: Tracks block production statistics from Solana validators.

For each database, follow these steps:

```bash
create database <database_name>
use <database_name>
```

#### Create Users

For each database, create a user and grant appropriate permissions:

```bash
create user <username> with password '<password>'
grant all on <database_name> to <username>
```

## Setup Watchtower

The watchtower is recommended to be installed in a separate box. We use watchtower for monitoring and alerting identity keys for Mainnet and Testnet. Critical metrics such as Identity balance and validator health are checked every minute.

#### Prerequisites

* Solana CLI < URL Solana CLI Docs >
* Python # Used for monitoring scripts
* Telegram Group
* Discord WEBHOOK

#### Installation

1. Install Solana CLI.
2. Create a service for agave watchtower. We recommend one service for each identity (Mainnet, Testnet, Debug).

```bash
nano /etc/systemd/system/agave-watchtower-mainnet.service
```

```bash
[Unit]
Description=Agave Watchtower Monitoring Service (Mainnet)
After=network.target

[Service]
ExecStart=/usr/local/bin/agave-watchtower \
  --url https://api.mainnet-beta.solana.com \
  --validator-identity [PUBKEY] \
  --interval 60 \                          
  --monitor-active-stake \
  --minimum-validator-identity-balance 5 \ # Minimum threshold for identity balance
  --rpc-timeout 30 \
  --name-suffix "server-name" \
  --unhealthy-threshold 1 \
  --ignore-http-bad-gateway
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

3. Enable the service

```bash
systemctl enable agave-watchtower-mainnet.service
```

4. Start the service

```bash
systemctl start agave-watchtower-mainnet.service
```

At this point we don't send alerts to Telegram and Discord yet. We want to capture the metrics for agave watchtower and format them with Python. Then, through another service, we send the alerts to Discord and Telegram.

### Create Formatting Service for Mainnet

1. Create the Python script

```bash
nano /usr/local/bin/solana-alert-formatter-mainnet.py
```

2. Script Execution Rights

```bash
chmod +x /usr/local/bin/solana-alert-formatter-mainnet.py
```

3. Create a service

```bash
nano /etc/systemd/system/solana-alert-formatter-mainnet.service
```

```bash
[Unit]
Description=Agave Watchtower Alert Formatter
After=agave-watchtower-mainnet.service  # This means this service only starts after the agave-watchtower-mainnet.service has been activated
Wants=agave-watchtower-mainnet.service

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/solana-alert-formatter-mainnet.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

This script is charged to send the alert to DISCORD and TELEGRAM Channels.\
Inside this script we have some variables we need to be aware of:

```bash
# Alert Intervals (in seconds)
VALIDATOR_DELINQUENT_ALERT_INTERVAL = 180  # Time between delinquent alerts (3 minutes)
LOW_BALANCE_ALERT_INTERVAL = 60 # Time between alerts when the validator has low balance
SUGGESTED_BALANCE = 10   # Suggested balance in SOL for identity accounts
# Enable/Disable specific alert types
ENABLE_DELINQUENT_ALERTS = True      # Set to False to disable validator delinquent alerts
ENABLE_RECOVERY_ALERTS = True        # Set to False to disable validator recovery alerts
ENABLE_LOW_BALANCE_ALERTS = True     # Set to False to disable low balance alerts
ENABLE_BALANCE_RECOVERY_ALERTS = True # Set to False to disable balance recovery alerts
# Communication platforms
ENABLE_DISCORD = True
ENABLE_TELEGRAM = True 
# Discord configuration
DISCORD_WEBHOOK = "webhooks_url"
# Telegram configuration
TELEGRAM_BOT_TOKEN = ""
TELEGRAM_CHAT_ID = ""
```

Entire Script < URL >

4. Enable the service

```bash
systemctl enable solana-alert-formatter-mainnet.service
```

5. Start the service

```bash
systemctl start solana-alert-formatter-mainnet.service
```

## Services Maintenance and Monitoring

We must be aware that every time a service is changed, we need to reload the daemon and then restart the service.

### Reload/Restart Systemd

```bash
systemctl daemon-reload
```

```bash
systemctl restart <SERVICE>
```

#### Checking Service Logs

To monitor the services and troubleshoot issues, use these commands:

```bash
systemctl status <SERVICE>
```

```bash
journalctl -u <SERVICE> -f
```

### Additional Configurations

Repeat the process for each identity (Mainnet, Testnet, Debug) by creating separate services with appropriate configurations for each environment.

## Setup Metrics

We pull metrics from several sources such as Stakewiz, Solana API, Solana CLI, Jpool, etc.

### Validator and Block Production Metrics

Create a service:

```bash
nano /etc/systemd/system/validator-metrics.service
```

```bash
[Unit]
Description=Stakewiz Validator Metrics Sender (every 2 minutes)
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/bin/bash -c 'while true; do /usr/local/bin/send_validator_metrics.sh & /usr/local/bin/send_block_metrics_v6.sh; wait; sleep 120; done'
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
```

The script "send\_block\_metrics\_v6.sh" will send the metrics to a separate database which is only dedicated for block production metrics.\
This script collects the metrics for block production through Solana CLI and also collects epoch information:

```bash
solana block <blocknumber>
solana epoch-info
```

### Configuration Variables

Here are some variables you should be aware of for this script:

```bash
# You can choose which networks to analyze by changing these variables to true/false
PROCESS_MAINNET=true
PROCESS_TESTNET=false  # Change to true if you want to process testnet
PROCESS_DEBUG=false    # Change to true if you want to process debug

# MAINNET
MAINNET_VOTE_ACCOUNT="<VOTEKEY>"
MAINNET_IDENTITY_KEY="<PUBKEY>"
MAINNET_RPC_API="https://api.mainnet-beta.solana.com"
MAINNET_HOST="<SERVERNAME>"

# ===== INFLUXDB CONFIGURATION =====
INFLUX_URL="https://influxdb-server-url:8086"
INFLUX_DB="validator_blocks"
INFLUX_USER="<DB_USER>"
INFLUX_PASS="<DB_PASSWORD>"  

# ===== PATH TO SOLANA BIN =====
SOLANA_BIN="/root/.local/share/solana/install/active_release/bin/solana"
```

This script "/usr/local/bin/send\_validator\_metrics.sh" obtains metrics from Solana clusters API and Solana CLI, else pulls metrics from stakewiz API.

Here are some variables you should be aware of for this script:

```bash
MAINNET_VOTE_ACCOUNT="<VOTEKEY>"
MAINNET_IDENTITY_KEY="<PUBKEY>"
MAINNET_RPC_API="https://api.mainnet-beta.solana.com"
MAINNET_HOST="<SERVERNAME>"
MAINNET_STAKEWIZ_ENABLED=true # If false don't pull metrics from stakewiz API 
MAINNET_GOSSIP_ENABLED=true 

# ===== INFLUXDB CONFIGURATION =====
INFLUX_URL="https://validator.secu.one:8086"
INFLUX_DB="<INFLUX_DATABASE>"
INFLUX_USER="<DB_USER>"
INFLUX_PASS="<DB_PASSWORD>"

# ===== ABSOLUTE PATH TO SOLANA BIN =====
SOLANA_BIN="/root/.local/share/solana/install/active_release/bin/solana"
```

### Script Execution Rights

```bash
chmod +x /usr/local/bin/send_block_metrics_v6.sh
chmod +x /usr/local/bin/send_validator_metrics.sh
```

## Setup JPool Rank Fetcher

JPool doesn't have an API which we can use to get metrics and scores, so we had to use scraping methods to get the metrics. JPool doesn't use Cloudflare Turnstile for captcha challenge, so we are able to get these metrics.

First we need to create a Python virtual environment to install some dependencies.

### Install Python Venv

```bash
sudo apt update
sudo apt install python3 python3-venv
```

### Create Virtual Environment

To isolate Python dependencies, create a virtual environment:

```bash
sudo python3 -m venv /root/venv
```

### Activate virtual environment

```bash
source /root/venv/bin/activate
```

### Install dependencies

Install the required Python packages inside the virtual environment:

```bash
/root/venv/bin/pip install flask playwright
# Install browser playwright, which is necessary for scraping 
/root/venv/bin/python -m playwright install
```

### Deactivate Environment

```bash
deactivate
```

### Create the service

```bash
nano /etc/systemd/system/tvc-api.service
```

```bash
[Unit]
Description=TVC Rank API with Flask and Playwright
After=network.target

[Service]
User=root
ExecStart=/root/venv/bin/python /usr/local/bin/get_tvc_rank.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

### Script Execution Rights

```bash
chmod +x /usr/local/bin/get_tvc_rank.py
```

### Enable the service

```bash
systemctl enable tvc-api.service
```

### Start the service

```bash
systemctl start tvc-api.service
```
