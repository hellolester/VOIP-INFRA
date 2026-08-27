# Network Design

[← Back to README](../README.md)

This is the authoritative reference for IP addressing, bridge design,
and the network separation rules for this environment. If anything in
another document conflicts with this file, **this file wins**.

## Physical Interfaces

| Interface | Role | Connected to | NIC | Driver |
|-----------|------|---------------|-----|--------|
| `eno1`    | Private/LAN NIC | Private LAN switch | onboard | — |
| `enp2s0`  | Public/VoIP NIC | Public switch | Realtek RTL8111/8168/8411 (PCI `02:00.0`) | `r8169` |

Verify NIC identity/driver at any time:

```
[PROXMOX HOST]
ethtool -i enp2s0
```

Expected output includes:

```
driver: r8169
version: 6.8.12-37-pve
bus-info: 0000:02:00.0
```

## Proxmox Bridges

| Bridge  | Backed by | Has IP? | Purpose |
|---------|-----------|---------|---------|
| `vmbr0` | `eno1`    | **Yes** — `192.168.10.181/24`, gateway `192.168.10.1` | Private LAN / Proxmox management |
| `vmbr1` | `enp2s0`  | **No** | Public VoIP network — public IP lives on the Issabel VM, not the bridge |

## IP Addressing Table

| Host | Interface | Address | Gateway |
|------|-----------|---------|---------|
| Proxmox Host (`noc01`) | `vmbr0` | `192.168.10.181/24` | `192.168.10.1` |
| Zabbix/Grafana LXC | — | `192.168.10.182` | `192.168.10.1` (assumed, private LAN) |
| Issabel 4 VM (VM 200) | `eth0` | `61.245.30.75/29` | `61.245.30.73` |

**Public network detail:**

| Property | Value |
|----------|-------|
| Network | `61.245.30.72/29` |
| Netmask | `255.255.255.248` |
| Usable range | `61.245.30.73` – `61.245.30.78` |
| Gateway | `61.245.30.73` |
| Issabel IP | `61.245.30.75` |
| Broadcast | `61.245.30.79` |

> The remaining usable addresses in this `/29` (e.g. `.74`, `.76`,
> `.77`, `.78`) are not documented here as allocated/unallocated —
> confirm with whoever manages the public IP block before reusing them.

## Network Path Diagrams

**Private path:**

```
Private Switch
    |
  eno1
    |
  vmbr0
    |
Proxmox Host 192.168.10.181/24
    |
Zabbix/Grafana LXC 192.168.10.182
```

**Public path:**

```
Public Switch
    |
  enp2s0
    |
  vmbr1
    |
Issabel VM 200 (net0, virtio, MAC BC:24:11:3F:23:CC)
    |
  eth0
    |
61.245.30.75/29
    |
Gateway 61.245.30.73
```

## Important Network Design Rule

This rule is intentionally repeated in multiple documents in this
repository because violating it can take down either the Proxmox
management network or the public PBX.

1. **Private stays private:** `eno1 → vmbr0` carries only
   `192.168.10.181` (Proxmox) and the private LAN. Never attach the
   public NIC or any public IP to `vmbr0`.
2. **Public stays public:** `enp2s0 → vmbr1` carries only the public
   VoIP network. `vmbr1` itself must **never** be assigned an IP
   address — especially not the Proxmox management IP.
3. **Issabel uses the public bridge:** VM 200's `net0` must be attached
   to `vmbr1`, not `vmbr0`.
4. **Issabel does not use its old private IP:** `192.168.10.187` was
   the original private address for Issabel and must not be
   reintroduced as its primary address. Issabel's primary address is
   the public `61.245.30.75/29`.
5. **No bridging between zones:** Do not create any bridge, route, or
   NAT rule at the Proxmox host level that connects `vmbr0` and
   `vmbr1`. Separation is the entire point of this design.

## `/etc/network/interfaces` (Proxmox Host)

The intended configuration (also stored as an example at
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

Apply changes safely — see [`proxmox-setup.md`](proxmox-setup.md) for
the full procedure including backups and verification.

## Related Documents

- [Architecture](architecture.md)
- [Proxmox Setup](proxmox-setup.md)
- [Issabel Networking](issabel-networking.md)
- [Troubleshooting History](troubleshooting-history.md)
