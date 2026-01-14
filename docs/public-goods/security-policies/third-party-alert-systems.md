---
description: >-
  Establish a systematic framework to identify, assess, and mitigate
  vulnerabilities in servers that interact with the Solana network, ensuring the
  confidentiality, integrity, and availability.
---

# Third-party Alert Systems

### Scope

This policy applies to all Ubuntu operating systems deployed on the Solana infrastructure, including validator nodes, RPCs, and monitoring servers, as well as to authorized personnel managing those systems.

### Vulnerability Identification

* Confidentiality: Alerts must be treated as sensitive information.
* Integrity: Alert sources must be verifiable and reliable.
* Availability: Alert systems must be operational 24/7.
* Legality: Compliance with current data protection and cybersecurity legislation.

### Early Warning Services

* Realize the vulnerabilities affecting the organization's systems as soon as they are published, which will reduce the time it takes to implement countermeasures.
* Industrialize the application of patches to mitigate vulnerabilities in our systems, as well as a proper continuity plan for monitoring them.
* Reduce the vulnerable attack perimeter after implementing the necessary control measures in security devices.
* Preempt potential attacks targeting the organization.
* Verify the functioning of the countermeasures implemented, ensuring their effectiveness.
* Increase the maturity of the cybersecurity present in the organization.

We suggest using the following tools:

* Wazuh / OSSEC

### Installing wazuh:

Following this quickstart implies deploying the Wazuh server, the Wazuh indexer, and the Wazuh dashboard on the same host. The table below shows the recommended hardware for a quickstart deployment:

<figure><img src="../.gitbook/assets/image (6).png" alt=""><figcaption></figcaption></figure>

Download and run the Wazuh installation assistant.

```bash
curl -sO https://packages.wazuh.com/4.13/wazuh-install.sh && sudo bash ./wazuh-install.sh -a
```

{% hint style="info" %}
Once the assistant finishes the installation, the output shows the access credentials and a message that confirms that the installation was successful.

INFO: --- Summary ---

INFO: You can access the web interface https://\<WAZUH\_DASHBOARD\_IP\_ADDRESS>

&#x20;   User: admin

&#x20;   Password: \<ADMIN\_PASSWORD>

INFO: Installation finished.
{% endhint %}

&#x20;Access the Wazuh web interface with and your credentials:

```
 https://<WAZUH_DASHBOARD_IP_ADDRESS> 
```

#### Deploy Agents:

{% hint style="info" %}
The Wazuh agent was developed considering the need to monitor a wide variety of different endpoints without impacting their performance. It is supported on the most popular operating systems, and it requires 35 MB of RAM on average.
{% endhint %}

The Wazuh agent provides key features to enhance your system’s security.

<figure><img src="../.gitbook/assets/image (7).png" alt=""><figcaption></figcaption></figure>



Add the Wazuh repository to download the official packages:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
```

```bash
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
```

```bash
apt-get update
```

#### Steps to deploy the Wazuh agent on your Linux endpoint:

Select your package manager and run the command below. Replace the WAZUH\_MANAGER value with your Wazuh manager IP address or hostname:

```bash
WAZUH_MANAGER="10.0.0.2" apt-get install wazuh-agent
```

```bash
systemctl daemon-reload --yes && systemctl enable wazuh-agent --yes && systemctl start wazuh-agent --yes
```

{% hint style="success" %}
Compatibility between the Wazuh agent and the Wazuh manager is guaranteed when the Wazuh manager version is later than or equal to that of the Wazuh agent. Therefore, we recommend disabling the Wazuh repository to prevent accidental upgrades. To do so, use the following command:
{% endhint %}

```bash
sed -i "s/^deb/#deb/" /etc/apt/sources.list.d/wazuh.list
```

```bash
apt-get update
```



Follow the official documentation to know how to create and maintain internal users:

{% embed url="https://documentation.wazuh.com/current/user-manual/user-administration/rbac.html#creating-and-setting-a-wazuh-admin-user" %}

Now, you can monitor your system. Vulnerability display manager example:

<figure><img src="../.gitbook/assets/image (8).png" alt=""><figcaption></figcaption></figure>



Alert display Management example:

<figure><img src="../.gitbook/assets/image (9).png" alt=""><figcaption></figcaption></figure>



### Other Alerts Systems:

We recommend staying informed about the latest vulnerabilities and zero days. Some of the systems you can subscribe to include:

* CISA Cybersecurity Alerts: [https://www.cisa.gov/news-events/cybersecurity-advisories](https://www.cisa.gov/news-events/cybersecurity-advisories)
* Solana Foundation: [https://solana.com/newsletter](https://solana.com/newsletter)

### Scope

This policy applies to all Ubuntu operating systems deployed on the Solana infrastructure, including validator nodes, RPCs, and monitoring servers, as well as to authorized personnel managing those systems.

### General principles

1. &#x20;Confidentiality: Alerts must be treated as sensitive information.
2. Integrity: Alert sources must be verifiable and reliable.
3. Availability: Alert systems must be operational 24/7.
4. Legality: Compliance with current data protection and cybersecurity legislation.

### Early Warning Services

