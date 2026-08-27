# Network Topology Diagram

[← Back to README](../README.md)

## Full Topology

```
                              ┌───────────────────────────────────────────┐
                              │              Proxmox Host                  │
                              │              noc01                         │
                              │                                             │
   Private LAN Switch         │   eno1 (Private/LAN NIC)                    │
   192.168.10.0/24 ───────────┼──────┐                                      │
                              │      │                                      │
                              │   vmbr0 (bridge)                            │
                              │   address 192.168.10.181/24                 │
                              │   gateway 192.168.10.1                      │
                              │      │                                      │
                              │      ├── Proxmox management (this host)      │
                              │      │                                      │
                              │      └── Zabbix/Grafana LXC                  │
                              │           192.168.10.182                    │
                              │                                             │
                              │   ─────────────────────────────────────    │
                              │                                             │
   Public Switch              │   enp2s0 (Public/VoIP NIC)                  │
   61.245.30.72/29 ───────────┼──────┐   Realtek RTL8111/8168/8411 (r8169)  │
                              │      │   PCI 02:00.0                        │
                              │      │                                      │
                              │   vmbr1 (bridge, NO IP)                     │
                              │      │                                      │
                              │      │  net0: virtio=BC:24:11:3F:23:CC       │
                              │      │        bridge=vmbr1, firewall=1      │
                              │      │                                      │
                              │   ┌──▼─────────────────┐                    │
                              │   │   VM 200            │                    │
                              │   │   Issabel4           │                   │
                              │   │   2 vCPU / 4096 MB    │                  │
                              │   │   40 GB disk          │                  │
                              │   │                       │                  │
                              │   │   eth0                │                  │
                              │   │   61.245.30.75/29      │                 │
                              │   │   gw 61.245.30.73       │                │
                              │   └───────────────────────┘                 │
                              └───────────────────────────────────────────┘
```

## Legend

| Symbol | Meaning |
|--------|---------|
| `eno1` / `enp2s0` | Physical NICs on the Proxmox host |
| `vmbr0` / `vmbr1` | Linux bridges on the Proxmox host |
| VM 200 | The Issabel 4 PBX virtual machine |

## Key Facts Encoded in This Diagram

- The private and public networks meet **only** inside the Proxmox
  host as two independent bridges — there is no bridging or routing
  between `vmbr0` and `vmbr1`.
- `vmbr1` carries no IP address of its own; the public IP belongs
  entirely to the Issabel VM.
- The Zabbix/Grafana LXC lives on the private side only.

See [`network-topology.txt`](network-topology.txt) for a plain-text
version suitable for pasting into terminals or tickets, and
[`../docs/network-design.md`](../docs/network-design.md) for the full
written design rules.
