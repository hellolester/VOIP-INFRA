# Issabel 4 Networking (`eth0`)

[← Back to README](../README.md)

Issabel 4 is CentOS-based. This document covers configuring its single
network interface, `eth0`, to use the **public** IP address directly
(this environment does not use a private IP + 1:1 NAT for the PBX — the
public IP is configured directly inside the VM).

## Target Configuration

| Property | Value |
|----------|-------|
| Device | `eth0` |
| IP address | `61.245.30.75` |
| Prefix | `/29` |
| Netmask | `255.255.255.248` |
| Gateway | `61.245.30.73` |
| DNS 1 | `8.8.8.8` |
| DNS 2 | `1.1.1.1` |

> **Historical note:** Issabel's original configuration used the
> private address `192.168.10.187` with gateway `192.168.10.1`. This
> was **intentionally changed** so Issabel uses the public IP directly.
> Do not revert to the private address as the primary configuration —
> see [`network-design.md`](network-design.md).

## Step 1 — Back Up Current Configuration

**[ISABEL 4 CONSOLE]**

```
cp /etc/sysconfig/network-scripts/ifcfg-eth0 \
/root/ifcfg-eth0.backup
```

**What it does:** Saves a copy of the current interface configuration
before making changes.

**Expected:** No output on success; a new file appears at
`/root/ifcfg-eth0.backup`.

## Step 2 — Write the Configuration

Edit `/etc/sysconfig/network-scripts/ifcfg-eth0` to contain (also
available as an example at
[`config/issabel/ifcfg-eth0.example`](../config/issabel/ifcfg-eth0.example)):

```
DEVICE=eth0
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=none
IPADDR=61.245.30.75
NETMASK=255.255.255.248
GATEWAY=61.245.30.73
DNS1=8.8.8.8
DNS2=1.1.1.1
```

## Step 3 — Restart Networking

**[ISABEL 4 CONSOLE]**

```
systemctl restart network
```

**What it does:** Reloads all network interfaces using the new
configuration.

**What failure looks like:** The command hangs, errors, or the console
session (if connected over the network) drops and does not come back.

**What to do next if it fails:** Use the Proxmox console (`qm monitor
200` won't give you a shell, but the Proxmox VM console in the web UI
will) to access the VM directly and inspect
`journalctl -u network` or `nmcli` / `ip addr` for errors. Restore from
backup if needed:

```
cp /root/ifcfg-eth0.backup /etc/sysconfig/network-scripts/ifcfg-eth0
systemctl restart network
```

## Step 4 — Verify

**[ISABEL 4 CONSOLE]**

```
ip -br addr
```

**Expected:**

```
eth0             UP             61.245.30.75/29
```

```
ip route
```

**Expected:** Includes a default route:

```
default via 61.245.30.73 dev eth0
```

```
ethtool eth0 | grep "Link detected"
```

**Expected:**

```
Link detected: yes
```

**If `Link detected: no`:** This means the VM's virtual NIC has no
link — almost always a Proxmox-side problem (VM not attached to
`vmbr1`, or `enp2s0` down on the host). Go back to
[`proxmox-setup.md`](proxmox-setup.md) and re-verify the host side
before troubleshooting further inside the VM.

## Step 5 — Verify Internet/Gateway Reachability

**[ISABEL 4 CONSOLE]**

```
ping -c 4 61.245.30.73
```

**Expected:** 4 replies from the gateway, 0% packet loss.

```
ping -c 4 8.8.8.8
```

**Expected:** 4 replies, confirming general internet reachability.

```
ping -c 4 google.com
```

**Expected:** 4 replies, confirming DNS resolution is also working
(uses `DNS1`/`DNS2` configured above).

**If gateway ping fails:** Problem is on the public network path
(cabling, switch, ISP/upstream router) or on `vmbr1`/`enp2s0` at the
Proxmox host. See [`runbooks/public-ip-failure.md`](../runbooks/public-ip-failure.md).

**If gateway ping succeeds but internet/DNS ping fails:** Problem is
upstream of the gateway, or a DNS-specific issue. Check
`/etc/resolv.conf` reflects `DNS1`/`DNS2`.

## Related Documents

- [Network Design](network-design.md)
- [Issabel 4 Installation](issabel4-installation.md)
- [Web Management](web-management.md)
- [Troubleshooting History](troubleshooting-history.md)
- [Runbook: Public IP Failure](../runbooks/public-ip-failure.md)
