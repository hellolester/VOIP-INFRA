# SIP Trunk

[← Back to README](../README.md)

This document describes how the SIP trunk to your upstream provider is
(or should be) configured. **No SIP provider, server, credentials, or
IP have been confirmed for this installation**, so every provider-
specific value below is a placeholder.

> ⚠️ **Never replace these placeholders with real values in this
> repository.** Store real credentials only in a local, git-ignored
> `.env` file based on
> [`templates/sip-provider.env.example`](../templates/sip-provider.env.example),
> or directly in the Issabel GUI/Asterisk config on the server itself.

## Placeholders

| Placeholder | Meaning |
|-------------|---------|
| `<SIP_PROVIDER>` | Name of the SIP/ITSP provider |
| `<SIP_SERVER>` | Provider's SIP server hostname |
| `<SIP_USERNAME>` | Trunk auth username |
| `<SIP_PASSWORD>` | Trunk auth password (never commit) |
| `<SIP_PROVIDER_IP>` | Provider's SIP server IP(s), if static (for firewall allow-listing) |
| `<SIP_DOMAIN>` | SIP domain/realm, if different from `<SIP_SERVER>` |
| `<SIP_PORT>` | SIP signaling port (commonly `5060/udp`, but verify — see below) |
| `<RTP_PORT_RANGE>` | RTP media port range (verify — see [`rtp-and-firewall.md`](rtp-and-firewall.md)) |

## SIP Signaling Port

SIP commonly uses **UDP 5060**, but this is not guaranteed:

- Some providers use TCP or TLS transport.
- Some providers use non-standard ports.
- Some installs run multiple trunks on different ports.

**Verify against your actual provider documentation and the actual
Asterisk/Issabel trunk configuration** before assuming `5060/udp` and
before opening firewall ports based on that assumption.

## Configuring the Trunk in Issabel

1. In the Issabel web GUI: `PBX → Trunks → Add SIP Trunk` (or PJSIP
   trunk, depending on which driver is in use — see
   [`voip-configuration.md`](voip-configuration.md)).
2. Enter `<SIP_SERVER>` / `<SIP_DOMAIN>` as the registration target.
3. Enter `<SIP_USERNAME>` / `<SIP_PASSWORD>` as provided by
   `<SIP_PROVIDER>`.
4. Set the correct transport/port (`<SIP_PORT>`) as documented by the
   provider.
5. Save and apply.

An example (placeholder-only) config file structure is provided at
[`config/issabel/asterisk/sip.conf.example`](../config/issabel/asterisk/sip.conf.example)
for reference — this is illustrative, not a working configuration.

## Verifying Registration

**[ISABEL 4 CONSOLE]**

For `chan_sip`:

```
asterisk -rx "sip show registry"
```

For PJSIP:

```
asterisk -rx "pjsip show registrations"
```

**Expected:** Registration state `Registered`.

**If not registered:** See
[`runbooks/sip-registration-failure.md`](../runbooks/sip-registration-failure.md).

## Common Symptom Patterns

| Symptom | Likely area |
|---------|-------------|
| SIP registers, but no audio on calls | RTP / NAT / firewall / media path — see [`rtp-and-firewall.md`](rtp-and-firewall.md) |
| Outbound calls work, inbound calls fail | DID mapping / provider-side routing / inbound route / firewall / trunk — see [`voip-configuration.md`](voip-configuration.md) |
| Inbound calls work, outbound calls fail | Outbound route / dial pattern / trunk selection / provider — see [`voip-configuration.md`](voip-configuration.md) |
| Trunk never registers | Credentials, server/domain, port, firewall blocking outbound SIP, or provider-side IP allow-listing |

## Related Documents

- [VoIP Configuration Overview](voip-configuration.md)
- [RTP and Firewall](rtp-and-firewall.md)
- [Runbook: SIP Registration Failure](../runbooks/sip-registration-failure.md)
- [Runbook: No VoIP Audio](../runbooks/no-voip-audio.md)
- [`templates/sip-provider.env.example`](../templates/sip-provider.env.example)
