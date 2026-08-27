# Architecture

[← Back to README](../README.md)

## Overview

A single Proxmox VE host (`noc01`) hosts:

1. A monitoring LXC container (Zabbix/Grafana) on the private LAN.
2. A QEMU virtual machine (**VM 200**, `Issabel4`) running Issabel 4,
   a CentOS-based Asterisk PBX distribution, connected directly to a
   **public** network.

The defining architectural decision in this environment is **physical
network separation**: the Proxmox host has two physical NICs, and each
is dedicated to a different bridge and a different trust zone.

```
                      ┌─────────────────────────────┐
                      │        Proxmox Host          │
                      │           (noc01)            │
                      │                               │
   Private LAN        │  eno1 ── vmbr0                │
  192.168.10.0/24 ────┼──────────┤ 192.168.10.181/24  │
                      │                               │
   Zabbix/Grafana     │          (LXC on vmbr0)        │
   192.168.10.182     │                               │
                      │                               │
   Public Network     │  enp2s0 ── vmbr1 (no IP)        │
  61.245.30.72/29 ────┼──────────┤                     │
                      │               │                │
                      │          net0 (virtio)          │
                      │               │                │
                      │        ┌─────────────┐          │
                      │        │   VM 200     │          │
                      │        │  Issabel4    │          │
                      │        │  eth0        │          │
                      │        │ 61.245.30.75 │          │
                      │        └─────────────┘          │
                      └─────────────────────────────┘
```

## Trust Zones

| Zone | Network | Purpose | Devices |
|------|---------|---------|---------|
| Private LAN | `192.168.10.0/24` | Proxmox management, monitoring | Proxmox host (`.181`), Zabbix/Grafana LXC (`.182`) |
| Public VoIP Network | `61.245.30.72/29` | SIP/RTP signaling, PBX web admin | Issabel 4 VM 200 (`.75`), gateway (`.73`) |

These two zones are **never bridged together**. The public zone has no
route back into the private LAN through Proxmox networking. Any
communication between the monitoring LXC and the Issabel VM (for
example, SNMP/agent-based monitoring) must be explicitly designed and
documented separately — it is not implied by this network layout.

## Why Physical Separation

- A compromise of the internet-facing Issabel VM does not automatically
  grant L2 access to the Proxmox management network.
- Proxmox's own web UI and SSH access stay on the private, non-routed
  LAN.
- Firewalling can be scoped tightly on the public side (`vmbr1`) without
  risk of accidentally affecting the management network.

## Key Components

| Component | Detail | Reference |
|-----------|--------|-----------|
| Proxmox Host | `noc01`, `192.168.10.181/24` | [`proxmox-setup.md`](proxmox-setup.md) |
| Private bridge | `vmbr0` on `eno1` | [`network-design.md`](network-design.md) |
| Public bridge | `vmbr1` on `enp2s0` | [`network-design.md`](network-design.md) |
| Issabel VM | VM 200, `Issabel4` | [`issabel4-installation.md`](issabel4-installation.md) |
| Issabel networking | `eth0`, `61.245.30.75/29` | [`issabel-networking.md`](issabel-networking.md) |
| VoIP stack | Asterisk (via Issabel 4) | [`voip-configuration.md`](voip-configuration.md) |

## Related Documents

- [Network Design](network-design.md)
- [Proxmox Setup](proxmox-setup.md)
- [Issabel 4 Installation](issabel4-installation.md)
- [Troubleshooting History](troubleshooting-history.md)
