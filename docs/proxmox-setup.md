# Proxmox Setup

[← Back to README](../README.md)

This document covers building/rebuilding the Proxmox host networking
from a fresh install. For the design rationale, see
[`network-design.md`](network-design.md).

## Prerequisites

- Proxmox VE installed on `noc01` with root/SSH console access.
- Physical access or out-of-band management (IPMI/iDRAC/console) in
  case a networking mistake disconnects the host — **strongly
  recommended** before touching `/etc/network/interfaces`.

## Step 1 — Identify Physical Interfaces

**[PROXMOX HOST]**

```
ip -br link
```

**What it does:** Lists all network interfaces and their state.

**Expected output:** Includes `eno1` and `enp2s0` among others.

Confirm the public NIC's identity:

```
lspci -nnk | grep -A4 -i ethernet
```

**Expected:** Shows the Realtek RTL8111/8168/8411 controller at PCI
address `02:00.0` using the `r8169` driver.

```
ethtool -i enp2s0
```

**Expected:**

```
driver: r8169
version: 6.8.12-37-pve
bus-info: 0000:02:00.0
```

## Step 2 — Verify/Bring Up Physical Link on `enp2s0`

**[PROXMOX HOST]**

```
ethtool enp2s0 | grep -E "Speed|Duplex|Link detected"
```

If this shows:

```
Link detected: no
```

then bring the interface up and re-check:

```
ip link set enp2s0 up
ethtool enp2s0 | grep -E "Speed|Duplex|Link detected"
```

**Expected after resolving the link:**

```
Speed: 1000Mb/s
Duplex: Full
Link detected: yes
```

**If it still says "no":** This is a physical-layer problem. Check:

- The cable is fully seated at both ends.
- The far-end switch port is enabled and not administratively down.
- Try a known-good cable and/or switch port.
- Confirm the switch port isn't configured for a VLAN/speed that the
  NIC can't negotiate.

See [`troubleshooting-history.md`](troubleshooting-history.md) for the
exact sequence used the first time this was diagnosed on this host.

## Step 3 — Back Up Current Network Configuration

**[PROXMOX HOST]**

Always back up before editing:

```
cp /etc/network/interfaces /root/interfaces.backup.$(date +%Y%m%d-%H%M%S)
```

## Step 4 — Configure `/etc/network/interfaces`

Edit `/etc/network/interfaces` to match the design in
[`network-design.md`](network-design.md) (also available as
[`config/proxmox/interfaces.example`](../config/proxmox/interfaces.example)):

```
auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.10.181/24
        gateway 192.168.10.1
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0

iface enp2s0 inet manual

auto vmbr1
iface vmbr1 inet manual
        bridge-ports enp2s0
        bridge-stp off
        bridge-fd 0

source /etc/network/interfaces.d/*
```

> **Do not** put an `address`/`gateway` line under `vmbr1`. It must stay
> `inet manual` with no IP. The Proxmox management IP
> (`192.168.10.181`) must remain solely on `vmbr0`.

## Step 5 — Apply Configuration Safely

Prefer `ifreload` (from `ifupdown2`, standard on modern Proxmox) over a
full network restart, since it applies changes with less risk of
dropping your current session:

**[PROXMOX HOST]**

```
ifreload -a
```

**What it does:** Re-reads `/etc/network/interfaces` and applies only
the differences, without a full interface flap when possible.

**If you are not sure `ifupdown2`/`ifreload` is installed, or if you
are on a very old Proxmox version:** test on a console session (not
only SSH) before running any full `systemctl restart networking`,
since that can drop your SSH session if `vmbr0` is misconfigured.

## Step 6 — Verify

**[PROXMOX HOST]**

```
ip -br link
```

**Expected:** `vmbr0` and `vmbr1` both `UP`.

```
bridge link
```

**Expected:** Shows `enp2s0` with `master vmbr1 state forwarding`.

```
bridge fdb show br vmbr1
```

**What it does:** Shows the MAC/forwarding table for `vmbr1`, useful
for confirming the Issabel VM's MAC (`BC:24:11:3F:23:CC`) is visible
once the VM is running.

Confirm the management IP is still correct and reachable from another
host on the private LAN:

```
ip -br addr show vmbr0
```

**Expected:** `192.168.10.181/24`.

## Step 7 — Create/Verify the Issabel VM

Continue to [`issabel4-installation.md`](issabel4-installation.md) to
create or verify VM 200 and attach it to `vmbr1`.

## Related Documents

- [Network Design](network-design.md)
- [Issabel 4 Installation](issabel4-installation.md)
- [Troubleshooting History](troubleshooting-history.md)
- [Command Reference](command-reference.md)
