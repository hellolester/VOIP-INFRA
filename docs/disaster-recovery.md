# Disaster Recovery

[← Back to README](../README.md)

Full ordered procedure to rebuild this environment from nothing (bare
Proxmox install) or from a partial failure. Follow the steps in order —
each step depends on the previous one working correctly. A printable
checklist version of the verification steps is in
[`templates/voip-checklist.md`](../templates/voip-checklist.md).

## Prerequisites

- Access to Proxmox VM backups (`vzdump` backups of VM 200) or the
  original Issabel 4 installation media, per
  [`backup-and-recovery.md`](backup-and-recovery.md).
- A copy of `/etc/network/interfaces` and `qm config 200` backups.
- Confirmed physical cabling: `eno1` to the private switch, `enp2s0` to
  the public switch.
- SIP trunk credentials (`<SIP_PROVIDER>`, `<SIP_USERNAME>`,
  `<SIP_PASSWORD>`, etc.) retrieved from your secure credential store
  (never from this repo).

## Procedure

### 1. Restore Proxmox

Reinstall Proxmox VE on `noc01` if the host itself was lost, or confirm
the existing install is healthy if only the VM/network was affected.

### 2. Restore Private Network

Configure `eno1` → `vmbr0` with `192.168.10.181/24`, gateway
`192.168.10.1`, per [`proxmox-setup.md`](proxmox-setup.md). Verify
management access before proceeding.

### 3. Restore Public NIC

Confirm `enp2s0` is present and identify it (`lspci`, `ethtool -i`).
Bring up the link (`ip link set enp2s0 up`) and confirm
`Speed: 1000Mb/s`, `Duplex: Full`, `Link detected: yes`.

### 4. Restore `vmbr1`

Create `vmbr1` with `enp2s0` as its bridge port, `inet manual`, **no
IP address**. Apply with `ifreload -a` and verify with `bridge link`.

### 5. Restore VM 200

Either restore from a `vzdump` backup, or recreate the VM per
[`issabel4-installation.md`](issabel4-installation.md) with the exact
specification (2 vCPU, 4096 MB RAM, 40 GB disk, virtio NIC
`BC:24:11:3F:23:CC` on `vmbr1`, firewall enabled).

### 6. Verify VM Network Device

```
qm config 200
```

Confirm:

```
net0: virtio=BC:24:11:3F:23:CC,bridge=vmbr1,firewall=1
```

### 7. Boot Issabel

```
qm start 200
qm status 200
```

Confirm `status: running`.

### 8. Verify `eth0`

Inside the VM console:

```
ip link show eth0
ethtool eth0 | grep "Link detected"
```

Expect `Link detected: yes`. If not, revisit steps 3–6.

### 9. Verify Public IP

```
ip -br addr
```

Expect `61.245.30.75/29` on `eth0`. If missing, restore/reapply
`/etc/sysconfig/network-scripts/ifcfg-eth0` per
[`issabel-networking.md`](issabel-networking.md).

### 10. Verify Gateway

```
ping -c 4 61.245.30.73
```

Expect 4 replies.

### 11. Verify Internet

```
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Expect replies from both (confirms routing and DNS).

### 12. Verify Apache

```
systemctl status httpd
curl -I http://127.0.0.1
```

Then confirm external access at `https://61.245.30.75`.

### 13. Verify Asterisk

```
systemctl status asterisk
asterisk -rx "core show version"
```

### 14. Verify SIP Trunk

```
asterisk -rx "sip show registry"
```

or

```
asterisk -rx "pjsip show registrations"
```

Expect `Registered`. If not, re-enter trunk credentials from your
secure credential store and see
[`runbooks/sip-registration-failure.md`](../runbooks/sip-registration-failure.md).

### 15. Verify Inbound Calls

Place a test call from an external phone to a known DID and confirm it
reaches the expected destination inside Issabel.

### 16. Verify Outbound Calls

Place a test call from an internal extension to an external number and
confirm it connects.

### 17. Verify RTP/Audio

Confirm two-way audio on both a test inbound and outbound call. If
audio fails, see [`runbooks/no-voip-audio.md`](../runbooks/no-voip-audio.md)
and [`rtp-and-firewall.md`](rtp-and-firewall.md).

### 18. Verify Firewall

Confirm only the intended ports are open (web admin, SIP, RTP, SSH) and
scoped as tightly as practical. See [`security.md`](security.md).

### 19. Verify Monitoring

Confirm the Zabbix/Grafana LXC (`192.168.10.182`) can reach/monitor
whatever it's configured to monitor, and that any alerting is active
again.

## Related Documents

- [Backup and Recovery](backup-and-recovery.md)
- [Proxmox Setup](proxmox-setup.md)
- [Issabel 4 Installation](issabel4-installation.md)
- [Issabel Networking](issabel-networking.md)
- [`runbooks/disaster-recovery.md`](../runbooks/disaster-recovery.md) — condensed runbook version
- [`templates/voip-checklist.md`](../templates/voip-checklist.md)
