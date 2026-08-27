# Runbook: Network Failure

[← Back to README](../README.md)

Use this runbook when the Proxmox host, the Issabel VM, or the network
path between them appears down.

## 1. Can You Reach the Proxmox Host at All?

Try SSH/web UI to `192.168.10.181`. If not, and you have no
out-of-band/console access, this is a physical-access problem — stop
here and arrange console access before proceeding.

If you have console access:

**[PROXMOX HOST]**

```
ip -br link
ip -br addr show vmbr0
```

**Expected:** `vmbr0` UP with `192.168.10.181/24`.

**If `vmbr0` is down or missing its IP:** Check
`/etc/network/interfaces` against
[`config/proxmox/interfaces.example`](../config/proxmox/interfaces.example).
If it was recently edited, restore from your backup
(`/root/interfaces.backup.*`) and re-apply with `ifreload -a`.

## 2. Run the Full Network Diagnostic

```
bash scripts/proxmox/check-network.sh
```

Review every `[FAIL]`/`[WARN]` line.

## 3. Check the Public Side Specifically

If the private/management side is fine but the public VoIP network is
the problem:

```
bash scripts/proxmox/check-public-bridge.sh
```

If `enp2s0` shows no link, see the physical-layer steps in
[`docs/proxmox-setup.md`](../docs/proxmox-setup.md) and the recorded
precedent in
[`docs/troubleshooting-history.md`](../docs/troubleshooting-history.md).

## 4. Check the VM Itself

```
bash scripts/proxmox/check-vm.sh
```

Confirm VM 200 is running and `net0` is attached to `vmbr1` with the
correct MAC.

## 5. Check Inside Issabel

If the Proxmox side looks healthy but Issabel itself seems
unreachable:

**[ISABEL 4 CONSOLE]** (via Proxmox VM console if network access is
unavailable)

```
bash scripts/issabel/check-network.sh
```

## 6. Still Unresolved?

Escalate to [`docs/troubleshooting.md`](../docs/troubleshooting.md)
for the full layer-by-layer checklist, and consider whether this has
become a full rebuild scenario — see
[`disaster-recovery.md`](disaster-recovery.md).

## Related Documents

- [Proxmox Setup](../docs/proxmox-setup.md)
- [Network Design](../docs/network-design.md)
- [Troubleshooting History](../docs/troubleshooting-history.md)
- [Public IP Failure Runbook](public-ip-failure.md)
