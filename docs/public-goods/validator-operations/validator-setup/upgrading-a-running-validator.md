# Upgrading a running validator

When performing an upgrade of a validator client on a host, several steps are involved including monitoring, the full workflow assumes the following terms:

`primary-host`: Is the host runing our Primary Identity which we want to upgrade

`secondary-host`: Is a host setup as hot-spare to later perform the identity swap

`demo-validator`: Is the keyset same for our validator. See [#naming-validators](../../hayek-validator-kit/ansible-control.md#naming-validators "mention")

Steps to upgrade a validator client:

1. Run `pb_setup_validator_jito` on `secondary-host` with **3.0.2** running co-hosted Jito relayer, and as a hot-spare of `demo-validator` keyset
2. Monitor `demo-validator` on its temporary hot-spare host `secondary-host` (now running with co-hosted Jito relayer)
3. Run "pb\_hot\_swap\_validator\_hosts" between `primary-host` ↔️  `secondary-host`
4. Monitor `demo-validator` on its new primary-target host `secondary-host` (now running with co-hosted Jito relayer)
5. Run `pb_setup_validator_jito` on `primary-host` with **3.0.2** running co-hosted Jito relayer, and as the hot-spare of `demo-validator` keyset
6. Monitor `demo-validator` on its temporary hot-spare host `primary-host` (now running with co-hosted Jito relayer)
7. Run `pb_hot_swap_validator_hosts` between `secondary-host` ↔️ `primary-host`
8. Monitor `demo-validator` on its new primary-target host `primary-host` (now running with co-hosted Jito relayer)
