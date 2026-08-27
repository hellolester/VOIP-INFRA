# Testing

[← Back to README](../README.md)

Procedures for validating the environment after any change. The
printable version of the checklist below lives at
[`templates/voip-checklist.md`](../templates/voip-checklist.md).

## Network Layer Tests

**[PROXMOX HOST]**

```
ethtool eno1 | grep "Link detected"
ethtool enp2s0 | grep -E "Speed|Duplex|Link detected"
ip -br link
bridge link
```

Expected: both NICs link-up, `vmbr0`/`vmbr1` up, `enp2s0` shows
`master vmbr1 state forwarding`.

**[ISABEL 4 CONSOLE]**

```
ip -br addr
ip route
ethtool eth0 | grep "Link detected"
```

Expected: `eth0` up with `61.245.30.75/29`, default route via
`61.245.30.73`, link detected yes.

## Connectivity Tests

**[ISABEL 4 CONSOLE]**

```
ping -c 4 61.245.30.73
ping -c 4 8.8.8.8
ping -c 4 google.com
```

Expected: all succeed (gateway, internet, DNS).

## Web Management Test

```
curl -I http://127.0.0.1
```

Then from an external machine, browse to `https://61.245.30.75` (and
`http://61.245.30.75` as fallback) and confirm the Issabel login page
loads.

## VoIP Tests

1. **Registration:** Confirm the SIP trunk shows `Registered`.
2. **Extension registration:** Confirm at least one test extension
   (softphone or desk phone) registers successfully.
3. **Outbound call:** Dial an external test number from a registered
   extension; confirm the call connects.
4. **Inbound call:** Call a known DID from an external phone; confirm
   it routes to the expected destination inside Issabel.
5. **Two-way audio:** On both the inbound and outbound test calls,
   confirm audio is heard clearly in both directions.
6. **Caller ID:** Confirm caller ID is presented correctly on both
   inbound and outbound legs, if your provider/configuration supports
   it.

## Full Printable Checklist

See [`templates/voip-checklist.md`](../templates/voip-checklist.md) for
a checklist covering Proxmox, Issabel, VoIP, and security items in one
place, suitable for printing or pasting into a change-management
ticket.

## Related Documents

- [Command Reference](command-reference.md)
- [Troubleshooting](troubleshooting.md)
- [`templates/voip-checklist.md`](../templates/voip-checklist.md)
