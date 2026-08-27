# Runbook: New Install

[← Back to README](../README.md)

Use this runbook when building this environment from a fresh Proxmox
install (not recovering from a failure — for that, see
[`disaster-recovery.md`](disaster-recovery.md)).

## 1. Proxmox Host Base Install

Install Proxmox VE on `noc01` following standard Proxmox installation
procedures (not covered in detail here — see official Proxmox
documentation). Set the initial management IP; this can be the final
`192.168.10.181/24` if the private network is available during
install, or a temporary address to be changed later.

## 2. Configure Proxmox Networking

Follow [`docs/proxmox-setup.md`](../docs/proxmox-setup.md) in full:
identify NICs, verify/bring up `enp2s0` link, back up, configure
`/etc/network/interfaces`, apply with `ifreload -a`, verify.

Run the diagnostic script to confirm:

```
bash scripts/proxmox/check-network.sh
```

## 3. Create the Issabel VM

Follow [`docs/issabel4-installation.md`](../docs/issabel4-installation.md):
create VM 200 with the documented spec (2 vCPU, 4096 MB, 40 GB disk,
virtio NIC on `vmbr1`, firewall enabled), attach Issabel 4 installation
media, and run the installer.

## 4. Configure Issabel Networking

Follow [`docs/issabel-networking.md`](../docs/issabel-networking.md):
back up, write `ifcfg-eth0` with the public IP configuration, restart
networking, verify link/IP/route/gateway/internet/DNS.

Run the diagnostic script to confirm:

```
bash scripts/issabel/check-network.sh
```

## 5. Confirm Web Management

Follow [`docs/web-management.md`](../docs/web-management.md) to
confirm `httpd` is running and reachable, both locally and externally.

```
bash scripts/issabel/check-web.sh
```

## 6. Configure VoIP

1. Confirm which SIP driver is active (chan_sip vs PJSIP) — see
   [`docs/voip-configuration.md`](../docs/voip-configuration.md).
2. Configure the SIP trunk with real (non-repository) credentials — see
   [`docs/sip-trunk.md`](../docs/sip-trunk.md).
3. Configure extensions, inbound routes/DIDs, and outbound
   routes/dial patterns through the Issabel GUI.
4. Confirm the actual RTP port range and open only the necessary
   firewall ports — see [`docs/rtp-and-firewall.md`](../docs/rtp-and-firewall.md).

Run the diagnostic script to confirm:

```
bash scripts/issabel/check-voip.sh
```

## 7. Test Everything

Work through [`templates/voip-checklist.md`](../templates/voip-checklist.md)
in full before considering the install complete.

## 8. Set Up Backups

Follow [`docs/backup-and-recovery.md`](../docs/backup-and-recovery.md):
schedule Proxmox VM backups, back up Issabel/Asterisk configuration,
and confirm backups land somewhere **off** the Proxmox host.

## 9. Review Security

Work through the hardening checklist in
[`docs/security.md`](../docs/security.md) before exposing the system
to production traffic.

## Related Documents

- [Architecture](../docs/architecture.md)
- [Network Design](../docs/network-design.md)
- [Testing](../docs/testing.md)
