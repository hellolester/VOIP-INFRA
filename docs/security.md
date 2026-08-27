# Security

[← Back to README](../README.md)

> This system is directly reachable from the public internet. Treat
> every recommendation here as mandatory, not optional.

## Never Commit These to Git

- SIP passwords and, where sensitive, SIP usernames
- API keys / tokens
- SSH private keys
- TLS private keys and certificate bundles containing private keys
- Web admin / OS passwords
- Backup credentials (e.g. remote storage access keys)
- Database passwords

This repository's [`.gitignore`](../.gitignore) is configured to help
prevent accidental commits of these, but **.gitignore is not a
substitute for care** — always review `git diff`/`git status` before
committing.

## Where Real Secrets Should Live Instead

- A local `.env` file (never committed) based on
  [`templates/sip-provider.env.example`](../templates/sip-provider.env.example).
- A password manager or secrets manager for admin/OS credentials.
- Directly in the Issabel GUI / Asterisk configuration on the server,
  which is not part of this Git repository.

If you ever discover a secret was accidentally committed, treat it as
**compromised**: rotate/change it immediately, then remove it from Git
history (not just a new commit) — a simple `git revert` does not
remove it from history.

## Hardening Checklist

- [ ] Strong, unique admin password for the Issabel web UI
- [ ] Strong, unique root/SSH password or key-based auth only for the
      underlying OS
- [ ] SSH access restricted to known/trusted source IPs where possible
- [ ] Web management (`80`/`443`) restricted to known/trusted source
      IPs where possible
- [ ] SIP signaling restricted to `<SIP_PROVIDER_IP>` where the
      provider's IP range is stable and documented
- [ ] RTP port range restricted appropriately (see
      [`rtp-and-firewall.md`](rtp-and-firewall.md)) — not opened wider
      than necessary
- [ ] Fail2ban or equivalent intrusion-prevention configured for
      SIP/SSH/web (if available on this Issabel version — confirm)
- [ ] No secrets present anywhere in this Git repository
- [ ] Backups completed and stored **off** the Proxmox host (see
      [`backup-and-recovery.md`](backup-and-recovery.md))
- [ ] Issabel/Asterisk kept patched to a supported version

## Public VoIP-Specific Risks

- **Toll fraud:** A compromised or misconfigured PBX can be used to
  place expensive international calls at your expense. Restrict
  outbound routes/dial patterns to what's actually needed, and monitor
  call detail records (CDR) for anomalies.
- **SIP scanning/brute force:** Public SIP ports are routinely scanned
  by bots attempting to register fraudulent extensions/trunks. IP
  restriction and strong extension passwords are the primary defenses.
- **Registration hijacking:** Weak extension passwords are a common
  entry point — enforce strong, unique passwords per extension.

## Related Documents

- [RTP and Firewall](rtp-and-firewall.md)
- [Backup and Recovery](backup-and-recovery.md)
- [`templates/sip-provider.env.example`](../templates/sip-provider.env.example)
- [`templates/firewall-rules.example`](../templates/firewall-rules.example)
