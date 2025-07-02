# Inspecting Logs

Log analysis is essential to understanding how a server is performing. In any infrastructure, reviewing logs from both the operating system and services is critical for detecting issues, verifying process health, and ensuring operational stability.\


## Audit Auth Logs

Review authentication logs to detect failed login attempts, `sudo` misuse, and other security-relevant events. Monitoring `/var/log/auth.log` helps identify unauthorized access and privilege escalation issues.



Show all failed `sudo` authentications

```bash
grep 'sudo: pam_unix(sudo:auth): authentication failure' /var/log/auth.log
```

Example output:

```bash
2025-06-24T22:39:30 node-01-nyc sudo: pam_unix(sudo:auth): authentication failure; logname=bob uid=1003 euid=0 tty=/dev/pts/4 ruser=bob rhost=  user=bob
```



To extract only the lines related to invalid SSH users or abrupt resets in `/var/log/auth.log`, use:

```bash
grep -E 'Invalid user|Connection reset by invalid user' /var/log/auth.log
```

Sample Output

```bash
2025-06-24T23:10:45 node-01-nyc sshd[3782288]: Connection reset by invalid user admin 45.135.232.177 port 27918 [preauth]
2025-06-24T23:10:49 node-01-nyc sshd[3782294]: Invalid user admin from 45.135.232.177 port 30478
```

{% hint style="info" %}
These log entries appear when an SSH connection attempt fails during the authentication phase:

> `Invalid user` indicates that the remote host attempted to log in with a non-existent or unauthorized username.
>
> `Connection reset by invalid user` means the SSH client disconnected abruptly before completing authentication — typically during a brute-force scan or failed login.

Most of the time, these connection attempts are made by automated bots scanning the internet for exposed SSH ports using default usernames like `admin`or`root.`
{% endhint %}

## Auditing Fail2ban Logs

`fail2ban` is a service that monitors logs for suspicious activity (e.g., failed SSH logins) and automatically blocks offending IPs via the firewall. This section covers how to review its actions via `/var/log/fail2ban.log`



View the most recent activity

```bash
tail -n 50 /var/log/fail2ban.log
```

Follow in real time

```bash
tail -f /var/log/fail2ban.log
```

IP Banned Example:

```bash
2025-06-24 23:31:29,582 fail2ban.filter [1477]: INFO    [sshd] Found 45.134.26.79 - 2025-06-24 23:31:29
2025-06-24 23:31:35,911 fail2ban.filter [1477]: INFO    [sshd] Found 45.134.26.79 - 2025-06-24 23:31:35
2025-06-24 23:31:40,582 fail2ban.filter [1477]: INFO    [sshd] Found 45.134.26.79 - 2025-06-24 23:31:40
2025-06-24 23:31:41,186 fail2ban.actions [1477]: WARNING [sshd] 45.134.26.79 already banned
```



## Auditing Logrotate Activity

`logrotate` is responsible for rotating, compressing, and deleting old log files to prevent disk usage from growing uncontrollably.&#x20;

If `logrotate` is managed by **systemd**, you can view the most recent log entries with:

```bash
journalctl -u logrotate.service
```

You can also check its dedicated log file at:

```bash
journalctl -u logrotate.service -n 100
```

{% hint style="danger" %}
If `logrotate` encounters an error, you'll see entries like this in the journal:
{% endhint %}

```bash
Jun 18 00:00:00 node-01-nyc systemd[1]: Starting logrotate.service - Rotate log files...
Jun 18 00:00:00 node-01-nyc systemctl[1143968]: Failed to kill unit agave-validator.service: Unit agave-validator.service not loaded.
Jun 18 00:00:00 node-01-nyc logrotate[1143947]: error: error running non-shared postrotate script for /home/sol/logs/agave-validator.log of '/home/sol/logs/agave-validator.log '
Jun 18 00:00:00 node-01-nyc systemd[1]: logrotate.service: Main process exited, code=exited, status=1/FAILURE
Jun 18 00:00:00 node-01-nyc systemd[1]: logrotate.service: Failed with result 'exit-code'.
Jun 18 00:00:00 node-01-nyc systemd[1]: Failed to start logrotate.service - Rotate log files.
```



## Solana Audit Logs

Solana validators generate comprehensive audit logs that are crucial for monitoring validator performance, detecting anomalies, and maintaining operational security. These logs provide detailed insights into validator operations, consensus participation, and network interactions.\


### Initial Startup Monitoring

After starting the validator service, immediately check the logs to verify proper initialization:

```batch
tail -f /home/sol/logs/solana-validator.log
```

If the validator is running correctly, you should immediately see snapshot download progress indicating the validator is synchronizing with the network:

<pre class="language-bash"><code class="lang-bash"><strong>[2025-05-12T14:05:19.401330892Z INFO solana_file_download] downloaded 3671850120 bytes 74.9% 51429008.0 bytes/s 
</strong><strong>[2025-05-12T14:05:19.401330892Z INFO solana_file_download] downloaded 3962403844 bytes 80.9% 48357188.0 bytes/s
</strong></code></pre>

{% hint style="warning" %}
The `tail` command will continue to display the output of a file as the file changes. You should see a continuous stream of log output as your validator runs. Keep an eye out for any lines that say `ERROR`.
{% endhint %}



## Jito Relayer Logs

To verify correct operation of the validator when connected to the Jito relayer and block engine, monitor these specific metrics in the validator logfile:

```bash
# Check block engine connection status
grep "block_engine_stage-stats" /home/sol/logs/agave-validator.log

# Check relayer connection status
grep "relayer_stage-stats" /home/sol/logs/agave-validator.log
```

These metrics are emitted once per second when properly connected:

`block_engine_stage-stats`: Indicates active connection to the block engine

```bash
[2025-06-28T04:00:00.656865431Z INFO solana_metrics::metrics] datapoint: block_engine_stage-stats num_bundles=0i num_bundle_packets=0i num_packets=0i num_empty_packets=0i 
[2025-06-28T04:00:01.657793890Z INFO solana_metrics::metrics] datapoint: block_engine_stage-stats num_bundles=0i num_bundle_packets=0i num_packets=0i num_empty_packets=0i 
[2025-06-28T04:00:02.657700858Z INFO solana_metrics::metrics] datapoint: block_engine_stage-stats num_bundles=0i num_bundle_packets=0i num_packets=0i num_empty_packets=0i 
```

`relayer_stage-stats`: Indicates active connection to the relayer

```bash
[2025-06-28T04:00:00.082448233Z INFO solana_metrics::metrics] datapoint: relayer_stage-stats num_empty_messages=0i num_packets=0i num_heartbeats=10i 
[2025-06-28T04:00:01.083020235Z INFO solana_metrics::metrics] datapoint: relayer_stage-stats num_empty_messages=0i num_packets=0i num_heartbeats=10i 
[2025-06-28T04:00:02.082646345Z INFO solana_metrics::metrics] datapoint: relayer_stage-stats num_empty_messages=0i num_packets=0i num_heartbeats=10i 
```



### Additional Verification of Correct Operation

After monitoring the server to identify that it's functioning correctly, in addition to the [Jito documentation](https://jito-foundation.gitbook.io/mev/jito-solana/checking-correct-operation) that indicates when it's running well in Co-hosted relayer, we also capture several lines in the Solana logs that indicate it's functioning correctly:

```bash
[2025-06-25T23:35:44.137520941Z INFO solana_core::proxy::block_engine_stage] connected to packet and bundle stream 
[2025-06-25T23:35:44.347979394Z INFO solana_metrics::metrics] datapoint: block_engine_stage-tokens_generated url="https://dallas.testnet.block-engine.jito.wtf" count=1i 
[2025-06-25T23:35:44.347996934Z INFO solana_metrics::metrics] datapoint: block_engine_stage-stats num_bundles=0i num_bundle_packets=0i num_packets=0i num_empty_packets=0i 
[2025-06-25T23:35:49.080362644Z INFO solana_metrics::metrics] datapoint: relayer_stage-tokens_generated url="http://127.0.0.1:11226" count=1i 
[2025-06-25T23:35:49.081398037Z INFO solana_core::proxy::relayer_stage] connected to packet stream 
[2025-06-25T23:35:49.082514240Z INFO solana_metrics::metrics] datapoint: relayer_stage-stats num_empty_messages=0i num_packets=0i num_heartbeats=0i
```

### Monitoring Slot Leadership

Another log that we should consider to verify that the relayer is functioning correctly is the validator's behavior when it becomes a leader slot .

```bash
tail -f /home/sol/logs/agave-validator.log | awk '/LEADER CHANGE/ && /hyt8ZV8sweXyxva1S9tibC4iTaixfFfx8icpGXtNDUJ/'
```

When your validator becomes the slot leader, you should see a message like this:

```bash
[2025-06-26T04:09:57.211398263Z INFO  solana_core::replay_stage] LEADER CHANGE at slot: 341906872 leader: hyt8ZV8sweXyxva1S9tibC4iTaixfFfx8icpGXtNDUJ. I am now the leader
```

Once the slot is produced, you should see a message indicating that your validator is no longer the leader:

```bash
[2025-06-26T04:09:59.436728586Z INFO solana_core::replay_stage] LEADER CHANGE at slot: 341906876 leader: ftvrBRwgptfes3AYAX1yMYnZHJsU4FA9d3KsvnXfqZk. I am no longer the leader
```

### **Authentication Error Handling**

It's also good to check the logs of the jito-relayer service:

```bash
journalctl -u jito-relayer.service -f
```

If you encounter this error: `error authenticating and connecting`

```bash
Jun 04 18:11:19 node-01-nyc run-jito-relayer.sh[337027]: [2025-06-04T22:11:19.744Z 
ERROR jito_block_engine::block_engine] error authenticating and connecting: 
AuthServiceFailure("status: PermissionDenied, message: "The supplied pubkey is not authorized to generate a token.", details: [], metadata: MetadataMap { headers: {"content-type": "application/grpc", "server": "jito-block-engine", "x-request-received-at": "2025-06-04T22:11:19.743Z", "content-length": "0", "date": "Wed, 04 Jun 2025 22:11:19 GMT", "x-envoy-upstream-service-time": "0"} }")
```

You must contact the Jito team and provide them with the pubkey that you will use for the relayer.
