# Changelog

All notable changes to this infrastructure and its documentation are
recorded here. Format loosely follows [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

- Fill in SIP provider details (`docs/sip-trunk.md`) once confirmed.
- Fill in actual Asterisk RTP port range once confirmed
  (`docs/rtp-and-firewall.md`).
- Confirm PJSIP vs chan_sip driver in use (`docs/voip-configuration.md`).

## [1.0.0] - 2026-08-27

### Added

- Initial repository created documenting the Proxmox + Issabel 4 public
  VoIP installation.
- Proxmox Host (`noc01`) network design: `eno1` → `vmbr0` (private LAN,
  `192.168.10.181/24`), `enp2s0` → `vmbr1` (public VoIP network, no IP
  on the bridge itself).
- Issabel 4 VM (VM 200) built: 2 vCPU, 4096 MB RAM, 40 GB disk, virtio
  NIC `BC:24:11:3F:23:CC` on `vmbr1`.
- Issabel `eth0` reconfigured from private IP `192.168.10.187` to
  public IP `61.245.30.75/29`, gateway `61.245.30.73`.
- Resolved `enp2s0` "Link detected: no" issue (see
  `docs/troubleshooting-history.md`).
- Diagnostic scripts added for Proxmox and Issabel network/VoIP checks.
- Full documentation set: architecture, network design, backup,
  disaster recovery, testing checklist, and runbooks.

### Security

- `.gitignore` configured to exclude real credentials, keys, and
  backups.
- All SIP/VoIP provider values represented as placeholders pending
  confirmation.
