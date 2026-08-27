# Command Reference

[← Back to README](../README.md)

Every command referenced elsewhere in this repository, grouped by
where it's run. All of these are **read-only/diagnostic** unless noted
otherwise.

## [PROXMOX HOST]

| Command | Purpose |
|---------|---------|
| `ip -br link` | List interfaces and link state briefly |
| `ip link set enp2s0 up` | Administratively bring up the public NIC *(state-changing — safe, does not affect existing config)* |
| `ethtool enp2s0` | Full NIC details |
| `ethtool enp2s0 \| grep -E "Speed\|Duplex\|Link detected"` | Quick link/speed/duplex check |
| `ethtool -i enp2s0` | Driver/firmware/bus info for the NIC |
| `lspci -nnk \| grep -A4 -i ethernet` | Identify Ethernet controllers at the PCI level |
| `cat /etc/network/interfaces` | View current bridge/interface configuration |
| `ifreload -a` | Apply changes to `/etc/network/interfaces` *(state-changing — see [`proxmox-setup.md`](proxmox-setup.md) for safe usage)* |
| `bridge link` | Show bridge port states (e.g. confirm `enp2s0` on `vmbr1`) |
| `bridge fdb show br vmbr1` | Show the forwarding/MAC table for `vmbr1` |
| `qm status 200` | Show VM 200 running/stopped state |
| `qm config 200` | Dump VM 200's full configuration |
| `qm monitor 200` | Open the QEMU monitor console for VM 200 |
| `info network` *(inside `qm monitor`)* | Show VM network device info from QEMU's perspective |
| `quit` *(inside `qm monitor`)* | Exit the QEMU monitor |
| `ip link show tap200i0` | Inspect the TAP interface Proxmox created for VM 200 |

## [ISABEL 4 CONSOLE]

| Command | Purpose |
|---------|---------|
| `ip -br addr` | Show IP addresses briefly |
| `ip route` | Show routing table (confirm default route) |
| `ip link show eth0` | Show `eth0` link-layer state |
| `ethtool eth0` | Full NIC details for `eth0` |
| `ethtool eth0 \| grep "Link detected"` | Quick link check |
| `cat /etc/sysconfig/network-scripts/ifcfg-eth0` | View current interface configuration |
| `cp /etc/sysconfig/network-scripts/ifcfg-eth0 /root/ifcfg-eth0.backup` | Back up interface config before editing |
| `systemctl restart network` | Apply interface configuration changes *(state-changing)* |
| `systemctl status network` | Check networking service status |
| `systemctl status httpd` | Check Apache/web admin service status |
| `netstat -tulpn \| grep -E ':80\|:443'` | Confirm what's listening on web ports |
| `curl -I http://127.0.0.1` | Confirm the local web server responds |
| `ping -c 4 61.245.30.73` | Test reachability of the public gateway |
| `ping -c 4 8.8.8.8` | Test general internet reachability |
| `ping -c 4 google.com` | Test DNS resolution + internet reachability |
| `asterisk -rx "sip show peers"` | List chan_sip peers/trunks |
| `asterisk -rx "sip show registry"` | Show chan_sip trunk registration state |
| `asterisk -rx "pjsip show endpoints"` | List PJSIP endpoints |
| `asterisk -rx "pjsip show registrations"` | Show PJSIP trunk registration state |
| `asterisk -rx "core show settings"` | Show core Asterisk settings, including RTP range |

## Notes

- Commands marked *(state-changing)* modify live configuration and
  should only be run after a backup and with an understanding of the
  rollback procedure — see the relevant doc linked above.
- All other commands in this table are read-only/diagnostic and safe
  to run at any time.

## Related Documents

- [Testing](testing.md)
- [Troubleshooting](troubleshooting.md)
- [Troubleshooting History](troubleshooting-history.md)
