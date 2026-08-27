# VoIP Configuration Overview

[← Back to README](../README.md)

Issabel 4 uses Asterisk as its underlying call engine. This document is
an overview and index; it intentionally does **not** hardcode a SIP
provider, credentials, or RTP range, since none were confirmed for this
installation. Fill in the placeholders after confirming your actual
setup, and never commit the real values (see [`security.md`](security.md)).

## Topics Covered by This Repository

| Topic | Where |
|-------|-------|
| SIP trunk (provider connection) | [`sip-trunk.md`](sip-trunk.md) |
| RTP media path & firewall | [`rtp-and-firewall.md`](rtp-and-firewall.md) |
| DIDs, inbound routes, outbound routes | Below |
| Extensions | Below |
| NAT considerations | [`rtp-and-firewall.md`](rtp-and-firewall.md) |
| Troubleshooting (registration, audio, calls) | [`troubleshooting.md`](troubleshooting.md) |

## Signaling Protocol: PJSIP vs chan_sip

Issabel 4 (like most Asterisk-based distros from this era) may ship
with either the legacy `chan_sip` driver or the newer `res_pjsip`
(PJSIP) stack, or both available. **This repository does not assume
which one is configured on this installation.**

Before making any changes, confirm which is actually active:

**[ISABEL 4 CONSOLE]**

```
asterisk -rx "sip show peers"
```

and/or

```
asterisk -rx "pjsip show endpoints"
```

Whichever command returns your configured trunk/extensions is the
driver actually in use. Document the answer here once confirmed:

> **Driver in use on this installation:** `<PJSIP_OR_CHAN_SIP>` *(fill
> in once confirmed)*

## Extensions

Extensions are configured through the Issabel web GUI
(`PBX → Extensions`) or directly in the underlying Asterisk
configuration. This repository does not enumerate specific extension
numbers, since they are operational data, not infrastructure design.
Record your extension numbering plan separately (e.g. in an internal
wiki or spreadsheet, not necessarily in this public/shared repo).

## Inbound Routes & DIDs

Inbound routing maps an incoming DID (the phone number provided by
your SIP provider) to a destination inside Issabel (an extension, ring
group, IVR, etc.).

Checklist when setting up or troubleshooting an inbound route:

- Confirm the DID as it will actually arrive in the `To:`/`Request-URI`
  of the incoming SIP INVITE (providers vary — full E.164, national
  format, or just the extension digits).
- Confirm the inbound route in Issabel matches that exact format (or
  uses a wildcard match if appropriate).
- Confirm the trunk carrying the call is the one you expect.

## Outbound Routes & Dial Patterns

Outbound routing maps a dialed pattern (what a user dials from an
extension) to a trunk and any digit manipulation needed before sending
the call to the provider.

Checklist:

- Confirm the dial pattern actually matches what users are dialing
  (including or excluding a leading `9`, `+`, country code, etc. as
  your dial plan requires).
- Confirm the correct trunk is selected, and in the correct priority
  order if multiple trunks/routes could match.
- Confirm any prepend/strip digit rules match what the provider
  expects on the outbound leg.

## Placeholders Used Throughout This Repository

```
<SIP_PROVIDER>
<SIP_SERVER>
<SIP_USERNAME>
<SIP_PASSWORD>
<SIP_PROVIDER_IP>
<SIP_DOMAIN>
<SIP_PORT>
<RTP_PORT_RANGE>
```

See [`templates/sip-provider.env.example`](../templates/sip-provider.env.example)
for a structured place to record these values **locally**, outside of
Git.

## Related Documents

- [SIP Trunk](sip-trunk.md)
- [RTP and Firewall](rtp-and-firewall.md)
- [Troubleshooting](troubleshooting.md)
- [Testing](testing.md)
