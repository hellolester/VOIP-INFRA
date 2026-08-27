# RTP and Firewall

[← Back to README](../README.md)

## SIP vs RTP — Two Separate Paths

SIP is only the **signaling** protocol — it sets up, modifies, and
tears down calls. The actual **audio** travels over a separate media
path using RTP (Real-time Transport Protocol), typically as a range of
UDP ports negotiated per-call.

This distinction is the root cause of the most common VoIP symptom:
**"the call connects, but there's no audio (or only one-way audio)"** —
SIP succeeded, but the RTP media path did not.

## RTP Port Range

A common Asterisk default is:

```
10000-20000/udp
```

**Do not assume this is the actual configured range on this
installation.** Verify it directly:

**[ISABEL 4 CONSOLE]**

```
asterisk -rx "core show settings"
```

or check the relevant configuration file directly (path/filename
depends on Issabel/Asterisk version — commonly `rtp.conf`):

```
cat /etc/asterisk/rtp.conf
```

An illustrative (placeholder) example is provided at
[`config/issabel/asterisk/rtp.conf.example`](../config/issabel/asterisk/rtp.conf.example) —
**confirm the real range on the server before using it to configure
any firewall.**

Record the confirmed range here once known:

> **Actual configured RTP range on this installation:** `<RTP_PORT_RANGE>`
> *(fill in once confirmed)*

## Firewall Ports to Consider

Only open what is actually needed, and only from where it's actually
needed (ideally scoped to `<SIP_PROVIDER_IP>` for the trunk, rather
than the entire internet, where the provider's IP range is stable and
known):

| Purpose | Protocol/Port | Scope |
|---------|----------------|-------|
| SIP signaling (trunk) | `<SIP_PORT>` (commonly UDP 5060, verify) | Ideally restricted to `<SIP_PROVIDER_IP>` |
| RTP media | `<RTP_PORT_RANGE>` (verify actual range) | Ideally restricted to `<SIP_PROVIDER_IP>`, though some providers use a wide/variable media IP range — check their documentation |
| Web management | TCP 80/443 | Restrict to known admin IPs where possible — see [`security.md`](security.md) |
| SSH | TCP 22 (or custom) | Restrict to known admin IPs — see [`security.md`](security.md) |

A placeholder firewall rule template is provided at
[`templates/firewall-rules.example`](../templates/firewall-rules.example).
Adapt it to whatever firewall implementation is actually in use
(Issabel's built-in firewall, iptables/firewalld directly, or the
Proxmox VM firewall on `vmbr1`/VM 200) — this is not assumed by this
repository.

## NAT Considerations

If Issabel is genuinely public (as in this design — a real public IP
directly on `eth0`, not behind NAT), classic "Asterisk behind NAT"
symptoms (wrong IP in SDP, etc.) are less likely than in a NATed
deployment, but can still occur if:

- Extensions/softphones/desk phones registering *to* Issabel are
  themselves behind NAT (very common) — this affects the "internal"
  leg, not the trunk.
- The SIP provider expects specific NAT-related SIP headers or
  behavior even for non-NATed customers — check provider documentation.

## Common Symptoms and Where to Look

| Symptom | Meaning | Where to look |
|---------|---------|----------------|
| SIP registers, but no audio at all | RTP media path never established | Firewall (RTP ports), RTP range mismatch, provider-side media IP filtering |
| One-way audio | RTP flowing in one direction only | NAT on one leg (often the phone/extension side), asymmetric firewall rules, provider SDP handling |
| Choppy/garbled audio | Packet loss/jitter on the RTP path, not usually a firewall on/off issue | Network quality, QoS, bandwidth, codec mismatch |

For step-by-step diagnosis, see
[`runbooks/no-voip-audio.md`](../runbooks/no-voip-audio.md).

## Related Documents

- [SIP Trunk](sip-trunk.md)
- [Security](security.md)
- [Runbook: No VoIP Audio](../runbooks/no-voip-audio.md)
- [`templates/firewall-rules.example`](../templates/firewall-rules.example)
