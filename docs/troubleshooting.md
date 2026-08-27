# Troubleshooting

[← Back to README](../README.md)

This is the general-purpose troubleshooting index. For step-by-step
guided procedures, use the [runbooks](../runbooks/) instead — this
document is a faster reference for someone who already knows roughly
where to look.

## Decision Tree

```
Is the Proxmox host itself reachable (SSH/console)?
  NO  -> Physical/out-of-band access required.
         See runbooks/network-failure.md

  YES -> Is VM 200 running? (qm status 200)
    NO  -> Start it: qm start 200
           Then re-check.

    YES -> Is eth0 UP inside Issabel with 61.245.30.75/29?
      NO  -> See docs/issabel-networking.md
             and runbooks/public-ip-failure.md

      YES -> Is the web admin reachable? (https://61.245.30.75)
        NO  -> See docs/web-management.md
               and runbooks/web-management-failure.md

        YES -> Is the SIP trunk registered?
          NO  -> See runbooks/sip-registration-failure.md

          YES -> Are calls connecting with audio?
            NO (no/one-way audio) -> runbooks/no-voip-audio.md
            NO (calls fail outright) -> docs/sip-trunk.md
                                          (check inbound/outbound routes)
            YES -> System healthy.
```

## Layer-by-Layer Checklist

1. **Physical/link layer** — `ethtool <iface> | grep -E "Speed|Duplex|Link detected"`
   on both `enp2s0` (Proxmox host) and `eth0` (inside Issabel).
2. **Bridge layer** — `bridge link` on the Proxmox host; confirm
   `enp2s0` shows `master vmbr1 state forwarding`.
3. **VM layer** — `qm status 200`, `qm config 200` — confirm running
   and attached to `vmbr1`.
4. **IP layer** — `ip -br addr` and `ip route` inside Issabel; confirm
   `61.245.30.75/29` and default route via `61.245.30.73`.
5. **Application layer (web)** — `systemctl status httpd`,
   `netstat -tulpn | grep -E ':80|:443'`, `curl -I http://127.0.0.1`.
6. **Application layer (VoIP)** — Asterisk service status, SIP/PJSIP
   registration state, RTP configuration — see
   [`voip-configuration.md`](voip-configuration.md) and
   [`sip-trunk.md`](sip-trunk.md).

## Quick Symptom Table

| Symptom | Most likely cause | Document |
|---------|--------------------|----------|
| Can't SSH/access Proxmox host at all | Private LAN issue, host down, `vmbr0` misconfigured | [`runbooks/network-failure.md`](../runbooks/network-failure.md) |
| `enp2s0` shows `Link detected: no` | Cable/switch port physical issue | [`troubleshooting-history.md`](troubleshooting-history.md), [`proxmox-setup.md`](proxmox-setup.md) |
| VM 200 won't start | Resource contention, storage issue, config error | `qm status 200`, Proxmox task log |
| Issabel `eth0` has no link | VM not attached to `vmbr1`, or `enp2s0` down on host | [`issabel-networking.md`](issabel-networking.md) |
| Can't reach web admin | `httpd` down, firewall, DNS/routing | [`web-management.md`](web-management.md) |
| SIP trunk won't register | Credentials, server/port, firewall | [`runbooks/sip-registration-failure.md`](../runbooks/sip-registration-failure.md) |
| No audio / one-way audio | RTP/NAT/firewall | [`runbooks/no-voip-audio.md`](../runbooks/no-voip-audio.md) |
| Inbound calls fail, outbound OK | DID/inbound route/provider | [`sip-trunk.md`](sip-trunk.md) |
| Outbound calls fail, inbound OK | Outbound route/dial pattern/trunk | [`sip-trunk.md`](sip-trunk.md) |

## Related Documents

- [Command Reference](command-reference.md)
- [Troubleshooting History](troubleshooting-history.md)
- [Runbooks index](../runbooks/)
