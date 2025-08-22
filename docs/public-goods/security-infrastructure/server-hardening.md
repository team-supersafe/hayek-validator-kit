# Server Hardening

{% hint style="danger" %}
Never try on production servers without first testing it in a controlled lab on test equipment.
{% endhint %}

Hardening is the process of securing a system by reducing its attack surface. The attack surface is the sum of all the ways an attacker can interact with a system, including open ports, services, and vulnerabilities. By hardening Ubuntu, you can minimize the potential entry points for attackers and protect your system from various threats, such as malware, brute-force attacks, and unauthorized access.

### Automated Security Hardening

{% hint style="info" %}
It's advisable to audit the system before applying any hardening fixes. This will help you create a point of comparison.
{% endhint %}

#### Using Lynis

Lynis is a powerful, open-source security auditing and compliance tool designed for Unix-based systems like Linux, macOS, and BSD. Created and maintained by CISOfy, Lynis is widely used by system administrators, DevOps engineers, and security professionals to assess the security posture of servers in real time.

Lynis not only identifies security gaps but also provides actionable suggestions and warnings, helping us harden our systems effectively. It supports standards such as CIS benchmarks, ISO27001, HIPAA, and PCI-DSS, making it ideal for organizations with compliance requirements.

**Step 1: Update**

```bash
sudo apt update && sudo apt upgrade -y
```

**Step 2: Install Lynis**

```bash
sudo apt install lynis -y
```

**Step 3: Verify Installation**&#x20;

```bash
lynis --version
```

**Step 4: Run a basic scan**

```bash
sudo lynis audit system
```

This inspects more than 200 system configurations and services like:

✅ Firewall settings

✅ Kernel parameters

✅ SSH, sudoers, and login policies

✅ File permissions

✅ Malware detection (via ClamAV)

✅ Logging and auditd configuration

**Step 5: Analyze audit results**

* After scanning, Lynis shows:

✅ Hardening index (0–100)

✅ Warnings (security issues)

✅ Suggestions (best practices)

* Log and summary files are saved at:

✅ /var/log/lynis.log

✅ /var/log/lynis-report.dat

**Step 6: Automate weekly scans**

&#x20;Use cron to schedule:

```bash
sudo crontab -e
```

Add:

```bash
0 2 * * 0 /opt/lynis/lynis audit system --quiet >> /var/log/weekly-lynis.log
```

{% hint style="info" %}
This runs every Sunday at 2 AM
{% endhint %}

**Step 7: Use a custom audit profile (Advanced)**

Create a profile for focused checks:

```bash
mkdir -p /etc/lynis/custom
cp /opt/lynis/default.prf /etc/lynis/custom/hardeningubuntu.prf
```

Edit it to include/exclude modules:

```bash
nano /etc/lynis/custom/hardeningubuntu.prf
```

Example:

```bash
skip-test=KRNL-5830  # skip IPv6 kernel test
enabled-test=AUTH-9222  # ensure sudo is protected
```

Run using the custom profile:

```bash
sudo ./lynis audit system --profile /etc/lynis/custom/hardeningubuntu.prf
```

**Step 8: Export and parse audit data**

You can extract specific security events:

```bash
grep "^warning" /var/log/lynis-report.dat
grep "^suggestion" /var/log/lynis-report.dat
```

### Hardening the System&#x20;

This is an editable version of a script that executes actions for CIS Compliance. This script should be reviewed and updated periodically with the latest security compliance recommendations.

{% hint style="danger" %}
Never try a new automation script on production servers without first testing it in a controlled lab on test equipment
{% endhint %}

### Run the following script:

{% file src="../.gitbook/assets/hardening-ubuntu-2404-v2 (1).sh" %}

### Perform gap analysis and audit again.

GAP analysis is a methodology used to evaluate the differences between the initial state of an organization's information systems and the level of compliance required by the standard it wants to comply with.

###

### Manual Security Hardening

Follow these steps to perform manual hardening:

#### Initial Setup

✅ Perform an audit with Lynis

✅ Review the audit results.

✅ Review, edit, and run the hardening script we attached in the previous session. You can adjust the following recommended hardening parameters in the script listed below:



#### Secure SSH Access

✅ Disable the root login.&#x20;

✅ Disable it by setting the PermitRootLogin value to no in the etc/ssh/sshd\_config file.&#x20;

✅ Change the default SSH port.&#x20;

✅ Uncomment and replace port 22 in etc/ssh/sshd\_config&#x20;

✅ Replace password authentication with SSH keys&#x20;

✅ Use key-based authentication only&#x20;

✅ Create a new SSH key pair&#x20;

✅ Disable password authentication by setting the PasswordAuthentication value to no in the etc/ssh/sshd\_config file.&#x20;

✅ Restart sshd to apply the changes.

#### Enable AppArmor

Check if AppArmor is active and enabled

```bash
sudo systemctl status apparmor
```

Activate and enable AppArmor&#x20;

```bash
sudo systemctl enable apparmor
sudo systemctl start apparmor
```

Check the currently active profiles

AppArmor profiles support two different modes of operation: enforce and complain. While enforce mode prevents applications from taking restricted actions, complain mode only logs those actions.

```batch
sudo apparmor_status
```

#### Enable the Firewall

Configure the firewall to allow only permit connections. Allow SSH and Solana validator ports:

| Port  | Service                                   |
| ----- | ----------------------------------------- |
| 8000  | Gossip Solana                             |
| 8001  | Gossip alternative Solana                 |
| 8899  | RPC public Solana                         |
| 8900  | WebSocket RPC Solana                      |
| 9000  | TPU (Transaction Processing Unit) Solana  |
| 7000  | Retransmission Solana                     |
| 10000 | Retransmission alternative Solana         |
| 8008  | HTTP proxy o debug service                |
| 8015  | cfg-cloud service                         |
| 8020  | intu-ec-svcdisc custom                    |



Start the firewall and set it to load at boot

```batch
sudo ufw enable
```

Enable firewall logging

```bash
sudo ufw logging on
```

#### Update and Upgrade

```batch
# Update the package information 
sudo apt update
# Simulate an upgrade of all packages
sudo apt-get upgrade -s
# If you’re satisfied with the simulation output, you can proceed to upgrade all packages.
sudo apt-get upgrade
```

If not, you can upgrade any individual packages one by one. Remember to replace $packagename with the name of each package.

```bash
sudo apt-get install --only-upgrade $packagename
```

#### Remove Unused Packages

```batch
sudo apt autoremove
```

Find and remove unused packages with Deborphan

```batch
sudo apt install deborphan
```

List the unused packages

```batch
deborphan
```

Remove the unused packages

```bash
apt-get remove $packagename
```

#### Use strong passwords

Use pwgen to generate a strong password

```batch
sudo apt install pwgen
```

Generate a list of passwords using the -ys flag, where y means include symbols, and s is used to generate a highly secure password string.

```bash
pwgen -ys 20 1
```

#### Set a password expiration policy

Use the etc/login.defs file to set a shorter password expiration policy, such as 30 to 90 days.

* `PASS_MAX_DAYS` is the number of days after which a password will expire.&#x20;
* `PASS_MIN_DAYS` is the number of days that need to pass before a password can be changed.
* `PASS_WARN_AGE` is the number of days warnings will be shown on log in before the password expires. This feature doesn’t extend the `PASS_MAX_DAYS` expiration.

Apply the new policy to existing users

```bash
sudo chage -l $username
sudo chage -M $days $username
```

#### Configuring Fail2Ban to protect SSH

```batch
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Now add your IP to the ignoreip list and uncomment the line and configure how the system should treat suspicious IPs.

• `bantime` defines how long an IP will be blocked.&#x20;

• `maxretry` is how many times an IP can fail to log in before getting blocked.&#x20;

• `findtime` is the time period after which the maxretry counter is reset.

Open the file “defaults-debian.conf ”

```batch
sudo nano /etc/fail2ban/jail.d/defaults-debian.conf 
```

```bash
[DEFAULT]
banaction = nftables
banaction_allports = nftables[type=allports]
backend = systemd

[sshd]
enabled = true
port = ssh
maxretry = 3
findtime = 300 
bantime = 3600
ignoreip = 127.0.0.1
```

Restart and check the service

```batch
sudo systemctl restart fail2ban
sudo systemctl status fail2ban
```

Monitoring and testing

```batch
sudo fail2ban-client status sshd
```

Unban manually:

```batch
sudo fail2ban-client unban --all
sudo fail2ban-client unban <ip-address>
```

***

#### What’s Next?

Network Security Hardening, configure a Bastion host or use the menu on the left to explore the rest of the documentation. If you’re just experimenting, localnet is all you need. If you’re going live, follow the full setup under Validator Operations.
