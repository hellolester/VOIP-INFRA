# Issabel Web Management

[← Back to README](../README.md)

## Access

| URL | Notes |
|-----|-------|
| `https://61.245.30.75` | Primary web management address |
| `http://61.245.30.75` | Fallback if HTTPS is not responding — investigate why, don't rely on this long-term |

> Restrict access to the web admin interface where possible (VPN, IP
> allow-list, or a firewall rule limiting the management port to known
> source IPs). See [`security.md`](security.md).

## Troubleshooting the Web Interface

**[ISABEL 4 CONSOLE]**

```
systemctl status httpd
```

**What it does:** Shows whether the Apache (`httpd`) service, which
serves the Issabel web UI, is running.

**Expected:** `active (running)`.

**If inactive/failed:**

```
systemctl start httpd
journalctl -u httpd -n 50 --no-pager
```

Review the log output for the specific error (permissions, port
conflict, misconfiguration) before restarting repeatedly.

```
netstat -tulpn | grep -E ':80|:443'
```

**What it does:** Shows which process is listening on ports 80/443.

**Expected:** `httpd` (or a related process) listed against `:80`
and/or `:443`.

**If nothing is listening:** `httpd` is not actually bound to the
port — check `systemctl status httpd` output and Apache's own config
for `Listen` directives.

**If a different, unexpected process is listening:** Something else is
bound to that port (port conflict). Identify the PID from `netstat`
output and confirm it's expected.

```
curl -I http://127.0.0.1
```

**What it does:** Confirms Apache is responding locally on the VM
itself, isolating whether the problem is the web server or something
external (firewall, routing, DNS).

**Expected:** An HTTP response header block (e.g. `HTTP/1.1 200 OK` or
a redirect).

**If this works locally but the site is unreachable externally:** The
problem is network/firewall related, not the web server itself. Check:

- The Issabel firewall isn't blocking ports 80/443 from the public
  network.
- The Proxmox VM firewall (since `firewall=1` is set on `net0`) isn't
  blocking the ports — check Proxmox's firewall rules for VM 200.
- Any upstream firewall/ACL on the public network segment.

## Related Documents

- [Issabel Networking](issabel-networking.md)
- [Security](security.md)
- [Runbook: Web Management Failure](../runbooks/web-management-failure.md)
- [Command Reference](command-reference.md)
