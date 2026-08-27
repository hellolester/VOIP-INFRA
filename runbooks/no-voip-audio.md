# Runbook: No VoIP Audio / One-Way Audio

[← Back to README](../README.md)

Use this runbook when calls connect (SIP signaling succeeds) but there
is no audio in one or both directions. Background reading:
[`docs/rtp-and-firewall.md`](../docs/rtp-and-firewall.md).

## 1. Confirm This Is a Media (RTP), Not Signaling, Problem

**[ISABEL 4 CONSOLE]**

```
asterisk -rx "sip show registry"
```

or

```
asterisk -rx "pjsip show registrations"
```

If the trunk isn't even registered, this isn't an audio problem — go
to [`sip-registration-failure.md`](sip-registration-failure.md)
instead.

If registered, and the call actually connects (you hear ringing,
answers, etc.) but audio is missing/one-way, continue below.

## 2. Confirm the Actual RTP Port Range

Do not assume `10000-20000`:

```
asterisk -rx "core show settings" | grep -i -A2 rtp
cat /etc/asterisk/rtp.conf
```

Record the real range if not already documented in
[`docs/rtp-and-firewall.md`](../docs/rtp-and-firewall.md).

## 3. Run the VoIP Diagnostic Script

```
bash scripts/issabel/check-voip.sh
```

Review the RTP configuration and recent log output for errors related
to media negotiation.

## 4. Check the Firewall

Confirm the actual firewall implementation in use (Issabel's own
firewall module, iptables/firewalld, and/or the Proxmox VM firewall on
`vmbr1`/VM 200) actually allows the confirmed RTP range in and out —
not just the SIP port. See
[`templates/firewall-rules.example`](../templates/firewall-rules.example)
for the concept; adapt to what's actually deployed.

**No audio at all (both directions):** Strong indicator that RTP is
being blocked entirely, or the RTP range configured in Asterisk doesn't
match what's allowed through the firewall.

**One-way audio:** Usually asymmetric — one leg of the call (often an
extension/softphone behind NAT) can send but not receive, or vice
versa. Check:

- Whether the affected endpoint is behind NAT and whether Issabel's
  NAT settings for that endpoint/extension are correct.
- Whether the firewall rule is genuinely bidirectional for the RTP
  range, not just inbound.

## 5. Check for Codec Mismatch / Choppy vs. Silent Audio

If audio is present but garbled/choppy rather than fully silent, this
is more likely a bandwidth/QoS/codec issue than a firewall issue — see
[`docs/rtp-and-firewall.md`](../docs/rtp-and-firewall.md) for the
distinction.

## 6. Test Again

After any firewall or NAT change, place a new test call — don't rely
on retrying the same already-negotiated call. Update
[`templates/voip-checklist.md`](../templates/voip-checklist.md)'s
audio-related items once confirmed working.

## Related Documents

- [RTP and Firewall](../docs/rtp-and-firewall.md)
- [SIP Trunk](../docs/sip-trunk.md)
- [SIP Registration Failure Runbook](sip-registration-failure.md)
- [Security](../docs/security.md)
