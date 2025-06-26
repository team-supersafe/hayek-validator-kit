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
