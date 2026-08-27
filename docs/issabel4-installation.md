# Issabel 4 Installation (VM 200)

[← Back to README](../README.md)

This document describes the Proxmox-side VM definition for the
Issabel 4 PBX. For OS-level networking inside the VM, see
[`issabel-networking.md`](issabel-networking.md). For VoIP application
configuration, see [`voip-configuration.md`](voip-configuration.md).

## VM Specification

| Property | Value |
|----------|-------|
| VM ID | 200 |
| VM Name | `Issabel4` |
| Type | QEMU virtual machine |
| CPU | 2 cores |
| Memory | 4096 MB |
| Disk | 40 GB |
| Network model | virtio |
| MAC address | `BC:24:11:3F:23:CC` |
| Bridge | `vmbr1` (public) |
| Firewall | enabled |

## Network Device Configuration

The VM's network device (`net0`) must be:

```
net0: virtio=BC:24:11:3F:23:CC,bridge=vmbr1,firewall=1
```

> **Critical:** This must reference `bridge=vmbr1`, never `vmbr0`. If
> you ever see `bridge=vmbr0` on VM 200's network device, the PBX will
> be attached to the private LAN instead of the public network — fix
> this immediately per [`network-design.md`](network-design.md).

## Installing Issabel 4 (Fresh Build)

If rebuilding VM 200 from scratch:

1. Create a new VM in Proxmox with the specification above (2 cores,
   4096 MB RAM, 40 GB disk, virtio NIC on `vmbr1`).
2. Attach the Issabel 4 installation ISO (obtain from the official
   Issabel project — this repository does not redistribute installation
   media).
3. Boot the VM and follow the Issabel 4 installer (CentOS-based
   installer with Issabel post-install configuration).
4. During/after installation, configure `eth0` as described in
   [`issabel-networking.md`](issabel-networking.md) — do **not** leave
   it on a DHCP or private address if the public IP is the intended
   final configuration.
5. Once networking is confirmed, proceed to
   [`voip-configuration.md`](voip-configuration.md).

## Verifying an Existing VM 200

**[PROXMOX HOST]**

```
qm status 200
```

**What it does:** Shows whether VM 200 is running, stopped, etc.

**Expected:** `status: running` (for a healthy, booted PBX).

```
qm config 200
```

**What it does:** Dumps the full VM configuration, including the
`net0` line above. Use this to confirm the bridge and MAC address are
correct, and as a backup artifact (see
[`backup-and-recovery.md`](backup-and-recovery.md)).

```
qm monitor 200
```

**What it does:** Opens the QEMU monitor console for the VM, useful for
advanced diagnostics (e.g. `info network`).

Inside the monitor:

```
info network
```

**Expected:** Shows the virtual NIC and its association with the tap
device backing `vmbr1`.

Exit the monitor with:

```
quit
```

## TAP Interfaces

Proxmox automatically creates a TAP interface (e.g. `tap200i0`) for VM
200's network device and attaches it to `vmbr1`. You can inspect this
for diagnostics:

```
ip link show tap200i0
bridge link
```

**Do not** manually create, delete, or reconfigure TAP interfaces.
They are managed automatically by Proxmox based on the VM's `net0`
configuration (`qm config 200`). If a TAP interface looks wrong, fix
the VM's network configuration (via the Proxmox UI or `qm set 200
-net0 ...`) rather than editing the TAP device directly.

## Related Documents

- [Proxmox Setup](proxmox-setup.md)
- [Issabel Networking](issabel-networking.md)
- [Troubleshooting History](troubleshooting-history.md)
- [Command Reference](command-reference.md)
