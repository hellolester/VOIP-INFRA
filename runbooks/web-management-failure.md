# Runbook: Web Management Failure

[← Back to README](../README.md)

Use this runbook when `https://61.245.30.75` (or the `http://`
fallback) is not loading.

## 1. Confirm Network Layer Is Healthy First

```
bash scripts/issabel/check-network.sh
```

If `eth0`/IP/routing is broken, fix that first — see
[`network-failure.md`](network-failure.md) — the web UI can't be
reached over a broken network regardless of Apache's state.

## 2. Run the Web Diagnostic Script

**[ISABEL 4 CONSOLE]**

```
bash scripts/issabel/check-web.sh
```

## 3. Check `httpd` Service State

```
systemctl status httpd
```

**If inactive/failed:**

```
systemctl start httpd
journalctl -u httpd -n 50 --no-pager
```

Read the actual error before restarting repeatedly — common causes
include port conflicts, misconfiguration after an update, or disk
space exhaustion (`df -h`).

## 4. Check What's Listening

```
netstat -tulpn | grep -E ':80|:443'
```

**Nothing listening:** Apache isn't bound to the port — check its
config for `Listen` directives and confirm it started cleanly.

**Something unexpected listening:** Identify the conflicting process
and resolve the conflict.

## 5. Test Locally Before Assuming Network/Firewall

```
curl -I http://127.0.0.1
```

**Works locally, fails externally:** This points to network/firewall,
not Apache. Check:

- Local firewall rules for ports 80/443 (Issabel firewall,
  iptables/firewalld).
- Proxmox VM firewall on VM 200 (`firewall=1` is set on `net0` — rules
  are managed through Proxmox's firewall UI/config for the VM).
- Any upstream firewall/ACL on the public network path.

**Fails locally too:** The problem is genuinely with Apache/the web
app — check logs (`/var/log/httpd/error_log` or the Issabel-specific
log location) for the underlying error.

## 6. Confirm External Reachability

From an external machine (not on the same network):

```
curl -I https://61.245.30.75
curl -I http://61.245.30.75
```

## Related Documents

- [Web Management](../docs/web-management.md)
- [Security](../docs/security.md)
- [Network Failure Runbook](network-failure.md)
