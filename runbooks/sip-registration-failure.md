# Runbook: SIP Registration Failure

[← Back to README](../README.md)

Use this runbook when the SIP trunk to `<SIP_PROVIDER>` will not
register.

## 1. Confirm Basic Network Reachability First

**[ISABEL 4 CONSOLE]**

```
ping -c 4 8.8.8.8
```

If general internet connectivity is broken, fix that first — see
[`docs/issabel-networking.md`](../docs/issabel-networking.md) and
[`network-failure.md`](network-failure.md). A trunk cannot register if
the VM has no internet path.

If you have `<SIP_PROVIDER_IP>` documented, test reachability to it
specifically:

```
ping -c 4 <SIP_PROVIDER_IP>
```

(Some providers block ICMP — a failed ping here isn't necessarily
conclusive, but a successful one is a good sign.)

## 2. Check Current Registration State

```
asterisk -rx "sip show registry"
```

or

```
asterisk -rx "pjsip show registrations"
```

Note the exact failure reason if shown (e.g. `Rejected`, `Timeout`,
`Auth failure`).

## 3. Verify Trunk Configuration

In the Issabel GUI (`PBX → Trunks`), confirm:

- `<SIP_SERVER>` / `<SIP_DOMAIN>` is correct and resolves via DNS.
- `<SIP_USERNAME>` / `<SIP_PASSWORD>` are correct (re-enter from your
  secure credential store if there's any doubt — do not guess).
- The configured port (`<SIP_PORT>`) matches what the provider expects
  — don't assume 5060/udp without checking provider docs.
- The transport (UDP/TCP/TLS) matches what the provider expects.

## 4. Check DNS Resolution of the SIP Server

```
nslookup <SIP_SERVER>
```

or

```
dig <SIP_SERVER>
```

**If this fails:** DNS is the problem, not the trunk config itself.
Check `DNS1`/`DNS2` in `ifcfg-eth0`
(see [`docs/issabel-networking.md`](../docs/issabel-networking.md)).

## 5. Check the Firewall (Outbound)

Registration requires **outbound** SIP traffic to reach the provider
and the provider's response to come back. Confirm outbound
`<SIP_PORT>` isn't blocked by any local firewall (Issabel's own,
iptables/firewalld, or the Proxmox VM firewall on VM 200/`vmbr1`).

## 6. Check the Firewall / IP Allow-Listing (Provider Side)

Some providers require your public IP (`61.245.30.75`) to be
allow-listed on their end before they'll accept registration.
Confirm with `<SIP_PROVIDER>` that `61.245.30.75` is authorized.

## 7. Check Logs for the Specific Rejection Reason

```
asterisk -rx "sip set debug on"
```

(chan_sip) or the PJSIP equivalent, then attempt registration again and
review:

```
tail -f /var/log/asterisk/full
```

**Turn debug logging back off when done** (`sip set debug off` /
equivalent) — verbose SIP debug logs can contain sensitive data and
add overhead.

## 8. Run the VoIP Diagnostic Script

```
bash scripts/issabel/check-voip.sh
```

## Related Documents

- [SIP Trunk](../docs/sip-trunk.md)
- [VoIP Configuration Overview](../docs/voip-configuration.md)
- [Issabel Networking](../docs/issabel-networking.md)
- [Security](../docs/security.md)
