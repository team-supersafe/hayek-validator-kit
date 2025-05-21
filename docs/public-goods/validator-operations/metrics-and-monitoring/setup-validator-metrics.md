# Setup Validator Metrics

## Setup Agave Watchtower

The watchtower is recommended to be installed in a separate box. We use watchtower for monitoring and alerting identity keys for Mainnet and Testnet. Critical metrics such as Identity balance and validator health are checked every minute.

### Prerequisites

- Solana CLI < URL Solana CLI Docs >
- Python # Used for monitoring scripts
- Telegram Group
- Discord WEBHOOK

### Installation

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

## Create Formatting Service for Mainnet

1. Create the Python script

```bash
nano /usr/local/bin/solana-alert-formatter-mainnet.py
```

2. Grant execution privileges for the script

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
This script is charged tosent the alert to DISCORD and TELEGRAM Chanels
Inside this sctipr we have some variables we need to be aware

```bash
# Alert Intervals (in seconds)
VALIDATOR_DELINQUENT_ALERT_INTERVAL = 180  # Time between delinquent alerts (3 minutes)
LOW_BALANCE_ALERT_INTERVAL = 60 # Time between alerts when the validator have low ballance
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

## Service Maintenance and Monitoring

We must be aware that every time a service is changed, we need to reload the daemon and then restart the service:

```bash
systemctl daemon-reload
```

```bash
systemctl restart <SERVICE>
```

### Checking Service Logs

To monitor the services and troubleshoot issues, use these commands:

```bash
systemctl status <SERVICE>
```

```bash
journalctl -u <SERVICE> -f
```

## Additional Configurations

Repeat the process for each identity (Mainnet, Testnet, Debug) by creating separate services with appropriate configurations for each environment.