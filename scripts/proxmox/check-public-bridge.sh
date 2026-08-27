#!/usr/bin/env bash
#
# check-public-bridge.sh — Focused check of the public VoIP bridge path
# (enp2s0 -> vmbr1 -> VM 200) (READ-ONLY)
#
# This script makes NO changes to the system. It is safe to run at
# any time.
#
# Run on: [PROXMOX HOST]
# Usage:  bash scripts/proxmox/check-public-bridge.sh

set -uo pipefail

PUBLIC_NIC="enp2s0"
PUBLIC_BRIDGE="vmbr1"
VMID="200"

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

section "Physical link: $PUBLIC_NIC"
if ip link show "$PUBLIC_NIC" >/dev/null 2>&1; then
    ethtool "$PUBLIC_NIC" 2>/dev/null | grep -E "Speed|Duplex|Link detected"
    LINK=$(ethtool "$PUBLIC_NIC" 2>/dev/null | grep "Link detected" | awk '{print $3}')
    if [ "$LINK" = "yes" ]; then
        echo "  [OK] Physical link detected on $PUBLIC_NIC."
    else
        echo "  [FAIL] No physical link detected on $PUBLIC_NIC."
        echo "         Check cabling and switch port. See docs/proxmox-setup.md."
    fi
else
    echo "  [FAIL] Interface $PUBLIC_NIC not found."
fi

section "Bridge: $PUBLIC_BRIDGE"
if ip link show "$PUBLIC_BRIDGE" >/dev/null 2>&1; then
    STATE=$(ip -br link show "$PUBLIC_BRIDGE" | awk '{print $2}')
    echo "  State: $STATE"
    ADDR=$(ip -br addr show "$PUBLIC_BRIDGE" | awk '{print $3}')
    if [ -n "$ADDR" ]; then
        echo "  [WARN] $PUBLIC_BRIDGE has an IP address ($ADDR) — it should have none."
    else
        echo "  [OK] $PUBLIC_BRIDGE has no IP address, as expected."
    fi
else
    echo "  [FAIL] Bridge $PUBLIC_BRIDGE not found."
fi

section "Bridge port membership"
bridge link 2>/dev/null | grep "$PUBLIC_NIC" || \
    echo "  [WARN] $PUBLIC_NIC not shown as a bridge port. Expected 'master $PUBLIC_BRIDGE'."

section "VM $VMID bridge attachment"
if command -v qm >/dev/null 2>&1; then
    NET0_LINE=$(qm config "$VMID" 2>/dev/null | grep '^net0:')
    echo "  $NET0_LINE"
    if echo "$NET0_LINE" | grep -q "bridge=$PUBLIC_BRIDGE"; then
        echo "  [OK] VM $VMID is attached to $PUBLIC_BRIDGE."
    else
        echo "  [WARN] VM $VMID net0 does not reference $PUBLIC_BRIDGE."
    fi
else
    echo "  [WARN] 'qm' not available — skipping VM check."
fi

section "Summary"
echo "This script made no changes. See docs/network-design.md for the"
echo "intended design and docs/troubleshooting-history.md for a record"
echo "of past issues with this exact bridge path."
