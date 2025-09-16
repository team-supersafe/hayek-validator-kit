---
description: >-
  Establish the principles and guidelines, ensuring the confidentiality,
  integrity, and availability of information, in accordance with ISO/IEC 27001.
---

# Continuous Monitoring

### Scope

This policy applies to all physical and virtual servers that are part of the Solana infrastructure, including validator nodes, RPCs, indexers, and monitoring servers, in both production and development environments.



### General Principles

* Continuous monitoring of logs, performance metrics, access, and security events.
* Tools used: Grafana, Watchtower.
* Automated alerts for critical events (authentication failures, configuration changes, unauthorized access).
* Secure log retention for a minimum of 12 months.
* Periodic review of monitoring systems and their configurations.



### Technical Procedures. Solana Node Monitoring:

* Enable RPC metrics on the Solana node with --enable-rpc-metrics.
* Configure Prometheus to collect metrics from port 9100.
* Create dashboards in Grafana for TPS, latency, CPU/RAM usage, and validator status.



### Exporting Metrics

Relevant metrics on a Solana server:

* TPS (Transactions per Second)
* Slot time y block time
* Validator Status (leader, delinquent, etc.)
* Use of CPU, RAM, disk
* Network latency and connected peers



For monitoring our validator, we use Telegraf, a lightweight metrics collection agent. It runs directly on the validator nodes and gathers various hardware metrics.

&#x20;

For validator-specific metrics (such as block production, vote credits, identity balance, etc.), we rely on the Stakeconomy scripts. All collected metrics are sent to an external time-series database powered by InfluxDB.



### Dashboards:

Solana exposes metrics in Prometheus format from the endpoint:

```
http://<NODE_IP>:9100/metrics
```

&#x20;

You can use the Node Exporter and configure Prometheus to collect:

* OS metrics
* Solana-validator process metrics

{% hint style="info" %}
For more information visit our section:\
[setup-validator-metrics](../validator-operations/metrics-and-monitoring/setup-validator-metrics.md)
{% endhint %}



### Monitoring with Watchtower

The watchtower is recommended to be installed in a separate box. We use watchtower for monitoring and alerting identity keys for Mainnet and Testnet. Critical metrics such as Identity balance and validator health are checked every minute.



* Register the node in Watchtower and configure alerts.

### Automated Alerts

We use Watchtower for monitoring the validator's health across the Solana cluster. Watchtower runs on a separate machine and continuously checks validator status. If it detects any issues (delinquency, low balance), it sends alerts through multiple channels such as:

&#x20;

* Telegraf
* Discord



**Prerequisites**

* Solana CLI
* Python
* Telegram Groups (Mainnet and Testnet)
* Discord WEBHOOK



### Hardware Alerts:

Define alerts on critical dashboards recommended by Solana, for example:

* TPS < 100 → possible congestion
* CPU usage > 90% → risk of falling
* RAM Usage > 90%



{% hint style="info" %}
For the installation and configuration of Grafana/influx see documentation:

[setup-validator-metrics](../validator-operations/metrics-and-monitoring/setup-validator-metrics.md)
{% endhint %}



### Log Retention and Auditing

Logs are stored by default in `/home/sol/logs/agave-validators.log` Recommended:

* Daily rotation.
* Uploading to a centralized system.



**Automate the review with custom tools or scripts that detect:**

* Connection retries
* Configuration changes
* Synchronization errors

{% hint style="info" %}
For more information, visit our section:&#x20;

[inspecting-logs](../validator-operations/metrics-and-monitoring/inspecting-logs.md)
{% endhint %}



### Complementary Services

* Solana Beach / Compass: Public APIs for network status.
* Stakewiz: Validator metrics and reputation.
* Solana Validator Health Check: Community scripts for health checks.



### Good practices aligned with ISO 27001

* Integrity: Use hashes or digital signatures on exported logs.
* Availability: Redundancy in metric storage.
* Confidentiality: Encrypt export channels (TLS in Prometheus).
* Audit: Maintain logs of metric access.
* Alerts: Configure alerts in Grafana for critical events (e.g., node downtime or high latency).
