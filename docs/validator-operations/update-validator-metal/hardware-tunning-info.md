# Hardware Tunning Info

Validators in Mainnet and Testnet always need to have post-provisioning hardware optimizations to make sure they are performing at maximum capacity on Solana.

The list below is not exhaustive, but it contains most of the optimizations that the Hayek Validator Kit automates on new servers using the Ansible role hw\_tuner, which is run automatically with every client playbook.

{% hint style="success" %}
These hardware optimizations are already part of the Hayek Validator Kit, and you don't have to run them manually on your validator server. This page is for information purposes only.
{% endhint %}

## References

* The community [Solana Hardware Compatibility List](https://solanahcl.org/)
* A popular Solana Discord thread about [Optimizing Your Solana Validator Setup ](https://discord.com/channels/428295358100013066/811317327609856081/1313787319299477574)
* A popular Solana Discord thread about [isolating one core for poh](https://discord.com/channels/428295358100013066/811317327609856081/1257995317190852651).&#x20;

## Unattended Upgrades <a href="#disable-ubuntu-24-need-to-restart-for-unattended-upgrades" id="disable-ubuntu-24-need-to-restart-for-unattended-upgrades"></a>

After Ubuntu 24, you need to make sure you disable unattended upgrades on your validator server.

### **Disable Manually**

First you must check the file `/etc/apt/apt.conf.d/99needrestart` and make sure there's no `-m u` CLI option there. See [this Ubuntu official forum discussion](broken-reference) for details.&#x20;

```sh
cat /etc/apt/apt.conf.d/99needrestart
```

If you see a line like the one blelow (which contains **`-m u`**)

```
DPkg::Post-Invoke {"test -x /usr/lib/needrestart/apt-pinvoke && /usr/lib/needrestart/apt-pinvoke -m u || true"; };
```

Edit the file and remove `-m u`

```sh
sudo nano /etc/apt/apt.conf.d/99needrestart
```

Save the file and exit nano: `CTRL+o`, `ENTER`, `CTROL+x` , and check again:

```sh
cat /etc/apt/apt.conf.d/99needrestart
# DPkg::Post-Invoke {"test -x /usr/lib/needrestart/apt-pinvoke && /usr/lib/needrestart/apt-pinvoke || true"; };

# Reboot to check
sudo reboot
```

### **Disable with Ansible**&#x20;

You can accomplish the same by running the following Ansible task. See [this Solana Discord Validator Support thread](https://discord.com/channels/428295358100013066/560174212967432193/1281336272211939410) for details on the origin of this task.

```ansible
- name: Prevent needsrestart from restarting services on it's own
  become: true
  become_user: root
  ansible.builtin.lineinfile:
    path: /etc/apt/apt.conf.d/99needrestart
    regexp: '^(.*needrestart/apt-pinvoke)(.*-m u)(.*)$'
    line: '\1\3'
    backrefs: yes
```

## System Update

Always make sure your server is up to date

```sh
sudo apt update
sudo apt upgrade
# it should not prompt you to restart any service because needsrestart 
# was configured to avoid restarting (previous step)
sudo reboot
```

## CPU scaling governor <a href="#configure-cpu-scaling-governor" id="configure-cpu-scaling-governor"></a>

There are multiple tune ups needed here. Follow the guide below for details:&#x20;

```sh
# check current cpu governor (powersave, performance, etc.)
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# if output is 'powersave' (or 'schedutil' ?) you'll need to set it to 'performance'

# check if cpufrequtils is installed
dpkg -l cpufrequtils

# install cpufrequtils
sudo apt install cpufrequtils

# configure scaling_governor for performance
# sudo bash -c 'echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
# The above didn't work
# Output: -bash: /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor: No such file or directory
# https://discord.com/channels/428295358100013066/1187805174803210341/1336544412729217168

# alternative1 from ChatGPT
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$cpu" > /dev/null
done
# alternative1 from ChatGPT (I used this one)
sudo bash -c 'for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo performance > "$cpu"; done'

# check again
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# performance
# performance
# ...
# performance
# performance

# The above change will not be permanent. If you reboot, the governor will be reset back to powersafe

# To make this change permanent
# See https://discord.com/channels/428295358100013066/560174212967432193/1274594663164149771
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils

# check that the cpufrequtils service is active
sudo systemctl status cpufrequtils.service

# Disbale the `ondemand` service if needed
# check if ondemand service is active
sudo systemctl status ondemand
# ● ondemand.service - Set the CPU Frequency Scaling governor
#      Loaded: loaded (/lib/systemd/system/ondemand.service; enabled; vendor preset: enabled)
#      Active: inactive (dead) since Fri 2025-02-28 18:37:19 UTC; 2min 13s ago
#     Process: 1586 ExecStart=/lib/systemd/set-cpufreq (code=exited, status=0/SUCCESS)
#    Main PID: 1586 (code=exited, status=0/SUCCESS)

# Feb 28 18:37:14 v-sw01 systemd[1]: Started Set the CPU Frequency Scaling governor.
# Feb 28 18:37:19 v-sw01 set-cpufreq[1586]: Setting powersave scheduler for all CPUs
# Feb 28 18:37:19 v-sw01 systemd[1]: ondemand.service: Succeeded.

# If output says "/lib/systemd/system/ondemand.service; enabled;" in line
# Loaded: loaded (/lib/systemd/system/ondemand.service; enabled; vendor preset: enabled)
# ... you'll need to disable it

sudo systemctl disable ondemand
# Removed /etc/systemd/system/multi-user.target.wants/ondemand.service.
# vsw01@v-sw01:~$ sudo systemctl status ondemand
# ● ondemand.service - Set the CPU Frequency Scaling governor
#      Loaded: loaded (/lib/systemd/system/ondemand.service; disabled; vendor preset: enabled)
#      Active: inactive (dead)

# Feb 28 18:37:14 v-sw01 systemd[1]: Started Set the CPU Frequency Scaling governor.
# Feb 28 18:37:19 v-sw01 set-cpufreq[1586]: Setting powersave scheduler for all CPUs
# Feb 28 18:37:19 v-sw01 systemd[1]: ondemand.service: Succeeded.

# Reboot
sudo reboot

# Check again
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# it should continue to show "performance"

# TODO: do we need to use cpupower instead of cpufrequtils because the later is deprecated ???
# See https://discord.com/channels/428295358100013066/560174212967432193/1274589805396885505

# Other commands
cat /etc/init.d/cpufrequtils
cpupower frequency-info
```

## Disable Swaps

On perf oriented setups, swap is completely disabled. vm.swappiness=0 means swap is still technically active. if you want max perf run without swaps and enough ram: swapoff -a.&#x20;

References [HERE](https://discord.com/channels/428295358100013066/811317327609856081/1337351764571193344) and [HERE](https://solanahcl.org).&#x20;

```sh
# show swap usage
swapon --show
# NAME      TYPE SIZE USED PRIO
# /swap.img file   8G   0B   -2

# check ram
free -h --si
#               total        used        free      shared  buff/cache   available
# Mem:           128G        1.0G         76G        2.0M         50G        126G
# Swap:          8.2G          0B        8.2G

# Temporarily turn off
sudo swapoff -a
# check
swapon --show # no output after disabling

# turn back on if needed with `sudo swapon -a`

# Permanently turn off swap
sudo nano /etc/fstab

# Then remove or comment out the line about swap
# /swap.img     none    swap    sw      0       0

# then reboot and check again
sudo reboot
swapon --show # no output after disabling
```

## Swappiness

&#x20;This is NOT NEEDED RIGHT NOW.

```sh
# show swappiness level
cat /proc/sys/vm/swappiness
sysctl vm.swappiness

# Temporarily change swappiness
sysctl -w vm.swappiness=10

# Permanently change swappiness
# Add below lines to your /etc/sysctl.conf file using 
sudo nano /etc/sysctl.conf
# Add
# # CHANGE SWAP
# vm.swappiness=x
# Here, x can be any number from 0 to 100 where:-

#     0 = disable swap
#     1 = minimum swap
#    10 = recommended for >2GB
#    60 = Linux Default for Swap
#   100 = Maximum Swap, for >1GB Ram
```

* See [https://askubuntu.com/questions/440326/how-can-i-turn-off-swap-permanently](https://askubuntu.com/questions/440326/how-can-i-turn-off-swap-permanently)
* See [https://linuxhint.com/change\_swap\_size\_ubuntu/](https://linuxhint.com/change_swap_size_ubuntu/)
* See [https://superuser.com/questions/925637/what-is-swap-and-how-to-disable-it-on-ubuntu-linux](https://superuser.com/questions/925637/what-is-swap-and-how-to-disable-it-on-ubuntu-linux)

## POH Core Affinity

This optimization should be done AFTER the agave validator is running.

* See [https://discord.com/channels/428295358100013066/811317327609856081/1257995317190852651](https://discord.com/channels/428295358100013066/811317327609856081/1257995317190852651)
* See [https://discord.com/channels/428295358100013066/811317327609856081/1343266582557626468](https://discord.com/channels/428295358100013066/811317327609856081/1343266582557626468)

{% code overflow="wrap" %}
```bash
# check hyper-threading
cat /sys/devices/system/cpu/smt/control

# install lstopo
sudo apt install hwloc

# find out the nearest available core. 
# in most cases, it's core 2 (cores 0 and 1 are often used by the kernel). 
# if you have more cores, you can choose the next available/unused nearest core.
lstopo

# look at the "cores" table to find your core and its hyperthread. 
# for example, if you choose core 2, its hyperthread might be 26 
lscpu --all -e

# this the easiest way to find the hyperthread a core. eg core 2:
cat /sys/devices/system/cpu/cpu2/topology/thread_siblings_list

# check current status
cat /etc/default/grub | grep GRUB_CMDLINE_LINUX_DEFAULT

# isolate the core and its hyperthread:
# in my case the hyperthread for core 2 is 26
# /etc/default/grub (dont forget to run update-grub and reboot afterwards)
sudo nano /etc/default/grub

# example where sibling of core 2 is 26
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_pstate=passive nohz_full=2,26 isolcpus=domain,managed_irq,2,26 irqaffinity=0-1,3-25,27-47"

# example where sibling of core 2 is 30
GRUB_CMDLINE_LINUX_DEFAULT="quiet amd_pstate=passive nohz_full=2,30 isolcpus=domain,managed_irq,2,30 irqaffinity=0-1,3-29,31-55"

sudo update-grub
# OUTPUT from localnet
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/init-select.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-5.4.0-208-generic
# Found initrd image: /boot/initrd.img-5.4.0-208-generic
# Found linux image: /boot/vmlinuz-5.4.0-205-generic
# Found initrd image: /boot/initrd.img-5.4.0-205-generic
# done

# OUTPUT from testnet (latitude)
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/50-curtin-settings.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-6.8.0-54-generic
# Found initrd image: /boot/initrd.img-6.8.0-54-generic
# Warning: os-prober will not be executed to detect other bootable partitions.
# Systems on them will not be added to the GRUB boot configuration.
# Check GRUB_DISABLE_OS_PROBER documentation entry.
# Adding boot menu entry for UEFI Firmware Settings ...
# done

sudo reboot
# nohz_full=2,26: enables full dynamic ticks for core 2 and its hyperthread 26 to reducing overhead and latency.
# isolcpus=domain,managed_irq,2,26: isolates core 2 and hyperthread 26 from the general scheduler
# irqaffinity=0-1,3-25,27-47: directs interrupts away from core 2 and hyperthread 26 
```
{% endcode %}

Now that you know for sure what is your nearest available core. Set the POH thread to core that core (2 in our example)

```sh
--experimental-poh-pinned-cpu-core 2 \
```

There is a [well-known bug in Anza's Agave validator software](https://github.com/anza-xyz/agave/issues/1968) related to core\_affinity if you isolate your cores. You can create a script to identify the `pid` of `solpohtickprod` and set it to your chosen core (eg. core 2 in our example)

```sh
#create and open a new script
nano fix_core_afinity_bug_for_poh.sh
```

Add this content

{% code overflow="wrap" %}
```sh
#!/bin/bash

# wait to load the binary

# main pid of solana-validator
solana_pid=$(pgrep -f "^agave-validator --identity")
if [ -z "$solana_pid" ]; then
    logger "set_affinity: solana_validator_404"
    exit 1
fi

# find thread id
thread_pid=$(ps -T -p $solana_pid -o spid,comm | grep 'solPohTickProd' | awk '{print $1}')
if [ -z "$thread_pid" ]; then
    logger "set_affinity: solPohTickProd_404"
    exit 1
fi

current_affinity=$(taskset -cp $thread_pid 2>&1 | awk '{print $NF}')
if [ "$current_affinity" == "2" ]; then
    logger "set_affinity: solPohTickProd_already_set"
    exit 1
else
    # set poh to cpu2
    sudo taskset -cp 2 $thread_pid
    logger "set_affinity: set_done"
     # $thread_pid
fi
```
{% endcode %}

Turn the script file into an executable and run it:

```sh
chmod u+x fix_core_afinity_bug_for_poh.sh
./fix_core_afinity_bug_for_poh.sh
```

By following these steps, core 2 will run at full speed without any TDP limits and any interrupts. In this example, core 2 runs at 5.9 GHz with overclocking.

{% hint style="danger" %}
If you restart your system, you need to manually run the script again.
{% endhint %}

{% hint style="warning" %}
This will not work on Intel architectures, only AMD. Do not use Intel.
{% endhint %}

See [this Solana Discord thread](https://discord.com/channels/428295358100013066/811317327609856081/1326129932212109312) related to this optimization.&#x20;
