# Maintenance

[← Back to README](../README.md)

Routine tasks to keep this environment healthy. Suggested cadence is a
starting point — adjust to your operational requirements.

## Weekly

- [ ] Review Asterisk/Issabel logs for repeated registration failures
      or unusual call patterns (possible toll fraud/scanning).
- [ ] Confirm the SIP trunk is still registered
      (`asterisk -rx "sip show registry"` or
      `asterisk -rx "pjsip show registrations"`).
- [ ] Confirm scheduled VM backups (`vzdump`) completed successfully.

## Monthly

- [ ] Run through [`templates/voip-checklist.md`](../templates/voip-checklist.md)
      in full.
- [ ] Review firewall rules against [`docs/rtp-and-firewall.md`](rtp-and-firewall.md)
      and [`docs/security.md`](security.md) — confirm nothing was
      opened wider than intended.
- [ ] Confirm off-host backup copies exist and are recent (see
      [`backup-and-recovery.md`](backup-and-recovery.md)).
- [ ] Review `docs/troubleshooting-history.md` for any recurring issues
      worth addressing at the root cause.

## Quarterly

- [ ] Test a restore from backup (VM-level or config-level) in a
      non-production context if feasible.
- [ ] Review and rotate credentials (SIP trunk password, admin
      passwords, SSH keys) per your security policy.
- [ ] Confirm Proxmox VE and Issabel 4 are running supported,
      reasonably current versions; plan upgrades if not.
- [ ] Re-verify physical link/speed/duplex on both `eno1` and `enp2s0`
      (cables degrade, ports get bumped).

## As-Needed

- Update this repository whenever the network design, VM
  specification, or VoIP configuration changes — this repo is only
  useful if it stays accurate. Record notable changes in
  [`CHANGELOG.md`](../CHANGELOG.md).
- Add new entries to [`docs/troubleshooting-history.md`](troubleshooting-history.md)
  after resolving any non-trivial incident.

## Related Documents

- [Backup and Recovery](backup-and-recovery.md)
- [Security](security.md)
- [Testing](testing.md)
