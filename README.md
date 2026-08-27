# Issabel 4 + Proxmox Public VoIP Infrastructure

Production runbook and documentation for a Proxmox VE host running an
Issabel 4 (Asterisk-based) PBX VM that is directly reachable on a public
IP address, physically separated from the private management LAN.

> **This is a public-facing VoIP server.** Read [`docs/security.md`](docs/security.md)
> before making any changes. Never commit secrets — see [Security Warning](#security-warning) below.

---

## Table of Contents

- [Project Purpose](#project-purpose)
- [Architecture](#architecture)
- [Network Diagram](#network-diagram)
- [IP Addressing](#ip-addressing)
- [Proxmox Bridge Design](#proxmox-bridge-design)
- [Issabel VM Design](#issabel-vm-design)
- [Installation Overview](#installation-overview)
- [Quick Troubleshooting](#quick-troubleshooting)
- [Security Warning](#security-warning)
- [VoIP Configuration Overview](#voip-configuration-overview)
- [Backup Strategy](#backup-strategy)
- [Recovery Strategy](#recovery-strategy)
- [Maintenance](#maintenance)
- [Documentation Index](#documentation-index)

---

## Project Purpose

This repository documents and partially automates (diagnostics only —
no destructive automation) a Proxmox VE host ("Proxmox Host") hosting a
single Issabel 4 VM ("VM 200") that acts as a public-facing VoIP/PBX
system (Asterisk).

The goals of this repository are:

1. Preserve the exact network design so it can be rebuilt months or
   years later without guesswork.
2. Provide safe, read-only diagnostic scripts for day-to-day
   troubleshooting.
3. Provide runbooks for common failure scenarios (network failure, no
   audio, SIP registration failure, disaster recovery).
4. Keep all secrets (SIP credentials, passwords, keys) **out of Git**.

## Architecture

The design enforces **physical and logical separation** between the
private management LAN and the public VoIP network:

- **Private LAN** — used for Proxmox management and internal monitoring
  (Zabbix/Grafana). Never exposed to the public internet.
- **Public VoIP Network** — used exclusively by the Issabel 4 VM for
  SIP/RTP traffic and web management. Never carries the Proxmox
  management IP.

See [`docs/architecture.md`](docs/architecture.md) and
[`docs/network-design.md`](docs/network-design.md) for full detail.

## Network Diagram

```
Private LAN
    |
   eno1
    |
  vmbr0
    |
Proxmox Host 192.168.10.181
    |
Zabbix/Grafana LXC 192.168.10.182


Public Network
    |
  enp2s0
    |
  vmbr1
    |
Issabel VM 200
    |
   eth0
    |
61.245.30.75/29
    |
Gateway 61.245.30.73
```

A more detailed ASCII/text diagram is available in
[`diagrams/network-topology.txt`](diagrams/network-topology.txt) and
[`diagrams/network-topology.md`](diagrams/network-topology.md).

## IP Addressing

| Host / Device                | Interface | IP Address           | Notes |
|-------------------------------|-----------|-----------------------|-------|
| Proxmox Host (`noc01`)        | vmbr0     | 192.168.10.181/24     | Management, private LAN |
| Zabbix/Grafana LXC             | —         | 192.168.10.182        | Monitoring, private LAN |
| Issabel 4 VM (VM 200)          | eth0      | 61.245.30.75/29       | Public VoIP network |
| Public gateway                 | —         | 61.245.30.73          | Public network gateway |
| Public network / broadcast     | —         | 61.245.30.72/29 · broadcast 61.245.30.79 | |

Full addressing detail: [`docs/network-design.md`](docs/network-design.md).

## Proxmox Bridge Design

| Bridge  | Physical NIC | Purpose            | Has IP? |
|---------|--------------|---------------------|---------|
| `vmbr0` | `eno1`       | Private LAN / management | Yes — `192.168.10.181/24` |
| `vmbr1` | `enp2s0`     | Public VoIP network       | **No** — the public IP lives on the Issabel VM, not on the bridge |

**Rule:** `vmbr1` must never carry the Proxmox management IP, and the
public network must never be bridged into `vmbr0`. See
[`docs/network-design.md`](docs/network-design.md) and
["Important Network Design Rule"](docs/network-design.md#important-network-design-rule).

## Issabel VM Design

| Property     | Value |
|--------------|-------|
| VM ID        | 200 |
| VM Name      | Issabel4 |
| Type         | QEMU |
| CPU          | 2 cores |
| Memory       | 4096 MB |
| Disk         | 40 GB |
| NIC model    | virtio |
| MAC address  | `BC:24:11:3F:23:CC` |
| Bridge       | `vmbr1` (public) — **not** `vmbr0` |
| Firewall     | enabled (`firewall=1`) |

Full config: [`docs/issabel4-installation.md`](docs/issabel4-installation.md).

## Installation Overview

1. Configure Proxmox networking — see [`docs/proxmox-setup.md`](docs/proxmox-setup.md).
2. Create/verify VM 200 — see [`docs/issabel4-installation.md`](docs/issabel4-installation.md).
3. Configure Issabel networking — see [`docs/issabel-networking.md`](docs/issabel-networking.md).
4. Configure VoIP (Asterisk/SIP trunk/extensions) — see
   [`docs/voip-configuration.md`](docs/voip-configuration.md) and
   [`docs/sip-trunk.md`](docs/sip-trunk.md).
5. Open only the required firewall ports — see
   [`docs/rtp-and-firewall.md`](docs/rtp-and-firewall.md).
6. Run through [`templates/voip-checklist.md`](templates/voip-checklist.md).

## Quick Troubleshooting

| Symptom | Start here |
|---------|------------|
| Proxmox host unreachable / network down | [`runbooks/network-failure.md`](runbooks/network-failure.md) |
| Web admin (`https://61.245.30.75`) not loading | [`runbooks/web-management-failure.md`](runbooks/web-management-failure.md) |
| SIP trunk won't register | [`runbooks/sip-registration-failure.md`](runbooks/sip-registration-failure.md) |
| Calls connect but no audio / one-way audio | [`runbooks/no-voip-audio.md`](runbooks/no-voip-audio.md) |
| Public IP unreachable | [`runbooks/public-ip-failure.md`](runbooks/public-ip-failure.md) |
| Full rebuild after catastrophic failure | [`runbooks/disaster-recovery.md`](runbooks/disaster-recovery.md) |

Full command list: [`docs/command-reference.md`](docs/command-reference.md).

## Security Warning

This system is directly reachable from the public internet. Read
[`docs/security.md`](docs/security.md) in full before deployment.

- **Never** commit SIP credentials, passwords, API keys, SSH keys, TLS
  keys, or backup credentials to this repository.
- Use the placeholders in [`templates/sip-provider.env.example`](templates/sip-provider.env.example)
  and copy them to a local, git-ignored `.env` file.
- Review [`.gitignore`](.gitignore) before adding any new file that
  might contain real configuration.
- Restrict web management, SSH, and (where possible) SIP signaling to
  known IP ranges.

## VoIP Configuration Overview

The Issabel 4 system runs Asterisk and provides:

- SIP trunk registration to an upstream provider (see
  [`docs/sip-trunk.md`](docs/sip-trunk.md))
- Inbound/outbound routing and DIDs
- Local extensions (PJSIP/chan_sip — verify which driver is actually in
  use on this install, see [`docs/voip-configuration.md`](docs/voip-configuration.md))
- RTP media handled separately from SIP signaling — see
  [`docs/rtp-and-firewall.md`](docs/rtp-and-firewall.md)

No SIP provider, credentials, or RTP port range are assumed in this
repository. Fill in the placeholders after confirming your actual
provider configuration.

## Backup Strategy

Summarized in [`docs/backup-and-recovery.md`](docs/backup-and-recovery.md).
At minimum:

- Proxmox: `/etc/network/interfaces`, `qm config 200`
- Issabel: `/etc/sysconfig/network-scripts/ifcfg-eth0`, Asterisk config,
  Issabel application config, firewall config

Backups should be copied **off** the Proxmox host (not stored only as
local files on the same physical server).

## Recovery Strategy

Full step-by-step disaster recovery sequence:
[`docs/disaster-recovery.md`](docs/disaster-recovery.md) and
[`runbooks/disaster-recovery.md`](runbooks/disaster-recovery.md).

## Maintenance

Routine maintenance tasks and cadence: [`docs/maintenance.md`](docs/maintenance.md).

## Documentation Index

| Document | Description |
|----------|-------------|
| [`docs/architecture.md`](docs/architecture.md) | High-level system architecture |
| [`docs/network-design.md`](docs/network-design.md) | Full IP/bridge/network design rules |
| [`docs/proxmox-setup.md`](docs/proxmox-setup.md) | Proxmox host + bridge configuration |
| [`docs/issabel4-installation.md`](docs/issabel4-installation.md) | VM 200 build spec |
| [`docs/issabel-networking.md`](docs/issabel-networking.md) | Issabel `eth0` public IP configuration |
| [`docs/voip-configuration.md`](docs/voip-configuration.md) | Asterisk/extensions/routes overview |
| [`docs/sip-trunk.md`](docs/sip-trunk.md) | SIP trunk setup & placeholders |
| [`docs/rtp-and-firewall.md`](docs/rtp-and-firewall.md) | RTP, NAT, and firewall guidance |
| [`docs/security.md`](docs/security.md) | Security requirements |
| [`docs/web-management.md`](docs/web-management.md) | Issabel web admin troubleshooting |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | General troubleshooting guide |
| [`docs/troubleshooting-history.md`](docs/troubleshooting-history.md) | Record of past incidents |
| [`docs/backup-and-recovery.md`](docs/backup-and-recovery.md) | Backup procedures |
| [`docs/disaster-recovery.md`](docs/disaster-recovery.md) | Full DR procedure |
| [`docs/maintenance.md`](docs/maintenance.md) | Ongoing maintenance |
| [`docs/testing.md`](docs/testing.md) | Test procedures |
| [`docs/command-reference.md`](docs/command-reference.md) | Every command used, in one place |

---

Licensed under the terms in [`LICENSE`](LICENSE). See
[`CHANGELOG.md`](CHANGELOG.md) for revision history.
