# Runbook: Disaster Recovery

[← Back to README](../README.md)

Condensed action list for a full rebuild. The complete, detailed
version with expected outputs at every step is
[`docs/disaster-recovery.md`](../docs/disaster-recovery.md) — use this
runbook as a quick-reference checklist while following that document.

## Prerequisites

- [ ] VM 200 backup (`vzdump`) available, or Issabel 4 install media
- [ ] Backup of `/etc/network/interfaces`
- [ ] Backup of `qm config 200`
- [ ] Backup of `ifcfg-eth0`
- [ ] SIP trunk credentials retrieved from secure storage (not this repo)
- [ ] Physical cabling confirmed: `eno1` → private switch, `enp2s0` → public switch

## Sequence

1. [ ] Restore Proxmox
2. [ ] Restore private network (`eno1` → `vmbr0`, `192.168.10.181/24`)
3. [ ] Restore public NIC (`enp2s0` link up, 1Gbps/full duplex)
4. [ ] Restore `vmbr1` (bridge on `enp2s0`, no IP)
5. [ ] Restore VM 200 (from backup or rebuilt per spec)
6. [ ] Verify VM network device (`net0: virtio=BC:24:11:3F:23:CC,bridge=vmbr1,firewall=1`)
7. [ ] Boot Issabel (`qm start 200`)
8. [ ] Verify `eth0` link
9. [ ] Verify public IP (`61.245.30.75/29`)
10. [ ] Verify gateway (`61.245.30.73`)
11. [ ] Verify internet (`8.8.8.8`, `google.com`)
12. [ ] Verify Apache (`httpd`, local + external)
13. [ ] Verify Asterisk service
14. [ ] Verify SIP trunk registration
15. [ ] Verify inbound test call
16. [ ] Verify outbound test call
17. [ ] Verify RTP/two-way audio
18. [ ] Verify firewall (only intended ports open)
19. [ ] Verify monitoring (Zabbix/Grafana LXC)

## Diagnostic Scripts to Run Along the Way

```
bash scripts/proxmox/check-network.sh
bash scripts/proxmox/check-vm.sh
bash scripts/proxmox/check-public-bridge.sh
bash scripts/issabel/check-network.sh
bash scripts/issabel/check-web.sh
bash scripts/issabel/check-voip.sh
```

## After Recovery

- [ ] Update [`docs/troubleshooting-history.md`](../docs/troubleshooting-history.md)
      with what caused the disaster and what was done.
- [ ] Confirm backups are still scheduled and landing off-host.
- [ ] Run the full [`templates/voip-checklist.md`](../templates/voip-checklist.md).

## Related Documents

- [Full Disaster Recovery Procedure](../docs/disaster-recovery.md)
- [Backup and Recovery](../docs/backup-and-recovery.md)
- [New Install Runbook](new-install.md)
