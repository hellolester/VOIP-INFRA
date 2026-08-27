# Backup and Recovery

[← Back to README](../README.md)

## What to Back Up

### Proxmox Host

| Item | Command | Notes |
|------|---------|-------|
| Network configuration | `cp /etc/network/interfaces /root/interfaces.backup.$(date +%Y%m%d)` | Do this before every edit, in addition to routine backups |
| VM 200 configuration | `qm config 200 > /root/vm200-config.backup.$(date +%Y%m%d).txt` | Captures the exact `net0` line, resources, etc. |
| Full VM backup | `vzdump 200 --storage <BACKUP_STORAGE> --mode snapshot` | Standard Proxmox VM backup — confirm target storage before running |

### Issabel 4 (inside the VM)

| Item | Path | Notes |
|------|------|-------|
| Network configuration | `/etc/sysconfig/network-scripts/ifcfg-eth0` | Back up before every edit (see [`issabel-networking.md`](issabel-networking.md)) |
| Asterisk configuration | `/etc/asterisk/` | Trunk, extensions, routing — contains credentials, treat as sensitive |
| Issabel application configuration/database | Issabel typically stores config in its own database and `/etc/` — use Issabel's own backup module (`System → Backup`) if available on this version |
| Firewall configuration | Wherever the active firewall implementation stores its rules (verify which is in use — see [`security.md`](security.md)) | |
| Application data (CDR, voicemail, recordings) | Varies by install — confirm actual paths on this system | |

## Backup Principles

1. **Back up before every change**, not just on a schedule. Every
   procedure in this repository that edits a config file includes a
   backup step for exactly this reason.
2. **Store backups off the Proxmox host.** A backup that lives only on
   the same physical server is not a real backup — it doesn't survive
   hardware failure, disk corruption, or ransomware. Copy backups to a
   separate host, NAS, or cloud storage.
3. **Never include real secrets in backups stored in this Git repo.**
   Backups of Asterisk config or the Issabel database will likely
   contain real credentials — store these separately from this
   repository, with appropriate access controls.
4. **Test restores periodically.** A backup you've never restored from
   is unverified. Periodically test restoring a VM backup or a config
   file backup in a non-production context if possible.

## Example: Scheduling Proxmox VM Backups

Proxmox has built-in scheduled backup support via the web UI
(`Datacenter → Backup`) or `vzdump`. Configure a job for VM 200 with:

- A retention policy appropriate to your storage capacity.
- A target storage that is **not** the same local disk as the VM's own
  virtual disk, ideally off-host entirely.

This repository does not prescribe a specific schedule or retention
policy — set this according to your organization's requirements.

## Restoring

See [`disaster-recovery.md`](disaster-recovery.md) for the full,
ordered restore procedure covering both Proxmox networking and the
Issabel VM.

## Related Documents

- [Disaster Recovery](disaster-recovery.md)
- [Security](security.md)
- [Maintenance](maintenance.md)
