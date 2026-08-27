# Troubleshooting History

[← Back to README](../README.md)

This document is a record of real incidents encountered while building
this environment, kept so the same diagnosis doesn't have to be
re-derived from scratch in the future. Add new entries at the top as
new incidents occur.

---

## Incident: `enp2s0` No Physical Link During Initial Build

**Symptom:**

The second physical Ethernet port intended for the public VoIP network
showed no link light, and Proxmox reported it down:

```
enp2s0           DOWN
```

```
ethtool enp2s0 | grep "Link detected"
Link detected: no
```

**Diagnosis steps:**

1. Confirmed NIC identity and driver:

   ```
   lspci -nnk | grep -A4 -i ethernet
   ```

   Result: Realtek RTL8111/8168/8411, driver `r8169`.

2. Brought the interface administratively up (it was down at the OS
   level, separate from the physical link question):

   ```
   ip link set enp2s0 up
   ```

3. Re-checked link state:

   ```
   ethtool enp2s0 | grep -E "Speed|Duplex|Link detected"
   ```

   Result:

   ```
   Speed: 1000Mb/s
   Duplex: Full
   Link detected: yes
   ```

**Resolution:** Bringing the interface up (`ip link set enp2s0 up`)
resolved the immediate "DOWN" state. The underlying physical
connection (cable/switch port) was confirmed good once the interface
was administratively enabled and negotiated 1000Mb/s full duplex.

**Follow-up:** After confirming link, `vmbr1` was created with
`enp2s0` as its bridge port (see [`proxmox-setup.md`](proxmox-setup.md)).

---

## Incident: `vmbr1` Creation and Verification

**Steps taken:**

1. Created `vmbr1` in `/etc/network/interfaces` with `enp2s0` as its
   bridge port (`inet manual`, no IP — see
   [`network-design.md`](network-design.md)).
2. Applied the configuration:

   ```
   ifreload -a
   ```

3. Verified:

   ```
   ip -br link
   bridge link
   ```

   Expected/confirmed output included:

   ```
   enp2s0 ... master vmbr1 state forwarding
   ```

**Result:** `vmbr1` came up correctly with `enp2s0` forwarding into it,
with no IP address on the bridge itself (by design).

---

## Incident: Issabel VM (VM 200) `eth0` Initially Down / No Carrier

**Symptom:**

After creating VM 200 and booting Issabel, `eth0` inside the VM showed
down/no carrier.

**Diagnosis steps:**

**[PROXMOX HOST]**

```
qm status 200
qm config 200
qm monitor 200
```

Inside the QEMU monitor:

```
info network
```

Also checked the TAP interface Proxmox creates for the VM:

```
ip link show tap200i0
bridge link
```

**Root cause / resolution:** The VM's network device needed to be
explicitly configured as:

```
net0: virtio=BC:24:11:3F:23:CC,bridge=vmbr1,firewall=1
```

Once `net0` was correctly attached to `vmbr1` (rather than left
unattached or on the wrong bridge), the TAP interface came up and
`eth0` inside the VM showed link.

**Lesson learned:** When a VM's interface shows no carrier, check the
VM's `net0` bridge assignment (`qm config 200`) before assuming a
guest-OS-level problem. Proxmox manages the TAP interface automatically
based on this configuration — it should not be hand-edited.

---

## Incident: Issabel Re-IP'd From Private to Public Address

**Context:** Issabel was originally configured with a private LAN
address (`192.168.10.187`, gateway `192.168.10.1`) during initial
bring-up/testing. This was **intentionally changed** to the final
public configuration.

**Change made:**

- Backed up `/etc/sysconfig/network-scripts/ifcfg-eth0` first.
- Reconfigured `eth0` to `61.245.30.75/29`, gateway `61.245.30.73`, DNS
  `8.8.8.8` / `1.1.1.1`.
- Restarted networking (`systemctl restart network`) and verified with
  `ip -br addr`, `ip route`, `ethtool eth0 | grep "Link detected"`.

**Full procedure documented in:** [`issabel-networking.md`](issabel-networking.md).

**Lesson learned:** `192.168.10.187` must never be reintroduced as
Issabel's primary address — see the design rule in
[`network-design.md`](network-design.md#important-network-design-rule).

---

## Template for New Entries

```
## Incident: <short title>

**Symptom:**

**Diagnosis steps:**

**Root cause / resolution:**

**Lesson learned:**
```

## Related Documents

- [Proxmox Setup](proxmox-setup.md)
- [Issabel Networking](issabel-networking.md)
- [Issabel 4 Installation](issabel4-installation.md)
- [Command Reference](command-reference.md)
