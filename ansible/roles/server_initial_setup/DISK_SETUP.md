# Disk Setup Role: Flexibility and Preparation

This documentation describes how the `server_initial_setup` role in the Hayek Validator Kit prepares and configures disks for Solana validator nodes, with a focus on its flexible handling of various data center provisioning scenarios.

## Overview

The disk setup logic is designed to support a wide range of bare metal server configurations, accommodating both ideal and non-ideal disk layouts as commonly encountered in data centers. The role automates the detection, assignment, formatting, and mounting of disks for Solana's ledger, accounts, and snapshots data, while ensuring system safety and performance.

## Preparation and Detection

- **Disk Discovery:**
  - The role enumerates all available block devices, excluding those already in use or mounted by the system.
  - It detects the root (OS) disk and distinguishes it from additional data disks.

- **Assignment Logic:**
  - Disks are assigned by descending size order:
    - The largest available disks are used for the ledger and accounts data.
    - If a third data disk is available, it is used for snapshots.
    - If only two data disks are available, the snapshots directory is placed on the root (OS) disk, ensuring the validator can still operate without a dedicated snapshots disk.

## Constraints

- **Safety Checks:**
  - The role will not format or remount the root (OS) disk, even if it is used for snapshots, to prevent data loss.
  - RAID configurations are permitted only for the OS/root disk. Any RAID detected on data disks will halt the playbook to avoid unsupported setups.
  - Existing mounts for ledger and accounts directories are not allowed and must be unmounted before proceeding.
    Running the role `server_initial_setup` again after the setup has completed and disks are initialized and mounted is a common scenario

- **Minimum Disk Requirements:**
  - The role expects at least two available data disks for optimal operation (ledger and accounts). If a third is present, it is used for snapshots; otherwise, snapshots are stored on the OS disk.

## Flexibility

- **Supports Common Data Center Layouts:**
  - Works with servers provisioned with:
    - Three or more NVMe drives. One as OS disk and two or more as data disks (ideal scenario).
    - Four disks or more. Two used as RAID-0/RAID-1 members mounted as root for the OS and two NVMe drives or more available for data (common in many providers).
    - Three disks. One RAID-0 for the OS and two NVMe drives as data disks (rare but also used).

- **Automatic Adaptation:**
  - The role automatically adapts to the detected disk layout, requiring no manual intervention or reconfiguration for most common scenarios.
  - It ensures that Solana's data directories are always placed on the best available disks, maximizing performance and reliability.

## Special Testnet Two-Disk Mode (Opt-In)

For exceptional testnet deployments with exactly two disks, the role includes a separate disk setup procedure:

- Activation requirements:
  - `solana_cluster=testnet`
  - `allow_unconventional_testnet_two_disk_layout=true`
- Safety behavior:
  - The default `disk_setup.yml` remains unchanged.
  - A dedicated task file is used instead (`disk_setup_testnet_two_disk.yml`).
  - The role fails fast if the opt-in variable is set outside testnet.
  - The role requires exactly 2 disks total in this mode (1 root + 1 non-root available).
- Layout in this mode:
  - `/mnt/accounts` on the non-root data disk.
  - `/mnt/ledger` and `/mnt/snapshots` as directories on the root filesystem.

## Summary

This disk setup role is robust and flexible, supporting a variety of server provisioning methods without requiring custom changes for each environment. It prioritizes safety, performance, and ease of use, making it suitable for both automated deployments and manual server setups in diverse data center environments.
