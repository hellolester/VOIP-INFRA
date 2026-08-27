# VoIP / Infrastructure Testing Checklist

[← Back to README](../README.md)

Printable checklist covering Proxmox, Issabel, VoIP, and security.
Use after any change, and monthly as routine verification (see
[`docs/maintenance.md`](../docs/maintenance.md)).

## Proxmox

- [ ] `eno1` link detected
- [ ] `enp2s0` link detected
- [ ] `enp2s0` negotiated 1Gbps / full duplex
- [ ] `vmbr0` UP with `192.168.10.181/24`
- [ ] `vmbr1` UP with **no** IP address
- [ ] `enp2s0` attached to `vmbr1` (`bridge link` shows `master vmbr1 state forwarding`)
- [ ] VM 200 running (`qm status 200`)
- [ ] VM 200 `net0` uses `bridge=vmbr1` (`qm config 200`)

## Issabel

- [ ] `eth0` UP
- [ ] `Link detected: yes`
- [ ] `61.245.30.75` configured on `eth0`
- [ ] `/29` prefix configured correctly
- [ ] `61.245.30.73` gateway reachable
- [ ] DNS resolution working
- [ ] Internet reachability confirmed (`ping 8.8.8.8`, `ping google.com`)
- [ ] Apache (`httpd`) running
- [ ] Web interface reachable at `https://61.245.30.75`
- [ ] Asterisk service running

## VoIP

- [ ] SIP trunk configured
- [ ] SIP trunk registration successful
- [ ] Test extension registered
- [ ] Outbound test call works
- [ ] Inbound test call works
- [ ] Two-way audio confirmed on test calls
- [ ] RTP media path confirmed working (no one-way/no audio)
- [ ] Caller ID correct on inbound/outbound
- [ ] Firewall tested (only intended ports open)

## Security

- [ ] Strong admin password set for Issabel web UI
- [ ] SSH access restricted where possible
- [ ] Web management access restricted where possible
- [ ] SIP provider IP filtering applied where possible
- [ ] RTP port range restricted appropriately
- [ ] No secrets present in this Git repository
- [ ] Backups completed and stored off the Proxmox host

---

**Date performed:** ______________________
**Performed by:** ______________________
**Notes / follow-up items:**

______________________________________________________
______________________________________________________
______________________________________________________
