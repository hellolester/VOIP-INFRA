# Runbook: Public IP Failure

[← Back to README](../README.md)

Use this runbook when the Issabel VM's public IP (`61.245.30.75`) is
unreachable, misconfigured, or missing.

## 1. Verify Inside the VM First

**[ISABEL 4 CONSOLE]**

```
ip -br addr
```

**If `61.245.30.75/29` is missing from `eth0`:**

```
cat /etc/sysconfig/network-scripts/ifcfg-eth0
```

Compare against
[`config/issabel/ifcfg-eth0.example`](../config/issabel/ifcfg-eth0.example).
If it doesn't match, restore from your backup
(`/root/ifcfg-eth0.backup`) or rewrite it per
[`docs/issabel-networking.md`](../docs/issabel-networking.md), then:

```
systemctl restart network
```

## 2. Check Link State

```
ethtool eth0 | grep "Link detected"
```

**If `Link detected: no`:** This is almost always a Proxmox-side
problem, not something fixable inside the VM. Go to step 3.

## 3. Check the Proxmox Side

**[PROXMOX HOST]**

```
bash scripts/proxmox/check-public-bridge.sh
```

This checks, in order: physical link on `enp2s0`, the `vmbr1` bridge
state and IP (should have none), bridge port membership, and VM 200's
`net0` bridge attachment. Fix whichever layer the script flags first —
lower layers must be healthy before higher layers can work.

## 4. Verify Gateway Reachability

**[ISABEL 4 CONSOLE]**

```
ping -c 4 61.245.30.73
```

**If this fails but link/IP look correct:** The problem is upstream of
the VM — the public switch, cabling, or the upstream router/ISP for
the `61.245.30.72/29` block. Confirm with whoever manages that public
IP allocation whether there's a known outage.

## 5. Verify Internet/DNS

```
ping -c 4 8.8.8.8
ping -c 4 google.com
```

## 6. Confirm the Design Hasn't Drifted

Double check none of the following have crept in (see
[`docs/network-design.md`](../docs/network-design.md)):

- `vmbr1` has accidentally been assigned an IP address.
- VM 200's `net0` has been changed to `bridge=vmbr0`.
- Issabel's `ifcfg-eth0` has reverted to the old private address
  `192.168.10.187`.

## Related Documents

- [Issabel Networking](../docs/issabel-networking.md)
- [Network Design](../docs/network-design.md)
- [Network Failure Runbook](network-failure.md)
- [Troubleshooting History](../docs/troubleshooting-history.md)
