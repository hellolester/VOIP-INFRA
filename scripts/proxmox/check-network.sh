#!/usr/bin/env bash
#
# check-network.sh — Proxmox Host network diagnostic (READ-ONLY)
#
# Checks eno1, enp2s0, vmbr0, vmbr1, link state/speed, bridge
# membership, and VM 200 configuration.
#
# This script makes NO changes to the system. It is safe to run at
# any time.
#
# Run on: [PROXMOX HOST]
# Usage:  bash scripts/proxmox/check-network.sh

set -uo pipefail

PRIVATE_NIC="eno1"
PUBLIC_NIC="enp2s0"
PRIVATE_BRIDGE="vmbr0"
PUBLIC_BRIDGE="vmbr1"
VMID="200"

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

check_iface_exists() {
    local iface="$1"
    if ! ip link show "$iface" >/dev/null 2>&1; then
        echo "  [FAIL] Interface $iface does not exist."
        return 1
    fi
    return 0
}

section "Interface overview (ip -br link)"
ip -br link

section "Private NIC: $PRIVATE_NIC"
if check_iface_exists "$PRIVATE_NIC"; then
    ethtool "$PRIVATE_NIC" 2>/dev/null | grep -E "Speed|Duplex|Link detected" || \
        echo "  [WARN] ethtool did not return expected fields for $PRIVATE_NIC"
fi

section "Public NIC: $PUBLIC_NIC"
if check_iface_exists "$PUBLIC_NIC"; then
    ethtool "$PUBLIC_NIC" 2>/dev/null | grep -E "Speed|Duplex|Link detected" || \
        echo "  [WARN] ethtool did not return expected fields for $PUBLIC_NIC"
    echo
    echo "  Driver info:"
    ethtool -i "$PUBLIC_NIC" 2>/dev/null | sed 's/^/    /'
fi

section "Private bridge: $PRIVATE_BRIDGE"
if check_iface_exists "$PRIVATE_BRIDGE"; then
    ip -br addr show "$PRIVATE_BRIDGE"
    echo "  Expected: 192.168.10.181/24"
fi

section "Public bridge: $PUBLIC_BRIDGE"
if check_iface_exists "$PUBLIC_BRIDGE"; then
    ip -br addr show "$PUBLIC_BRIDGE"
    ADDR=$(ip -br addr show "$PUBLIC_BRIDGE" | awk '{print $3}')
    if [ -n "$ADDR" ]; then
        echo "  [WARN] $PUBLIC_BRIDGE has an IP address ($ADDR)."
        echo "         By design, $PUBLIC_BRIDGE should have NO IP address."
        echo "         See docs/network-design.md."
    else
        echo "  [OK] $PUBLIC_BRIDGE has no IP address, as expected."
    fi
fi

section "Bridge membership (bridge link)"
bridge link 2>/dev/null || echo "  [WARN] 'bridge' command not available or failed."

section "Bridge forwarding table for $PUBLIC_BRIDGE"
bridge fdb show br "$PUBLIC_BRIDGE" 2>/dev/null || \
    echo "  [WARN] Could not read fdb for $PUBLIC_BRIDGE."

section "VM $VMID status"
if command -v qm >/dev/null 2>&1; then
    qm status "$VMID" 2>&1
else
    echo "  [WARN] 'qm' command not found — is this being run on a Proxmox host?"
fi

section "VM $VMID configuration"
if command -v qm >/dev/null 2>&1; then
    qm config "$VMID" 2>&1
    NET0=$(qm config "$VMID" 2>/dev/null | grep '^net0:')
    if echo "$NET0" | grep -q "bridge=$PUBLIC_BRIDGE"; then
        echo
        echo "  [OK] VM $VMID net0 is attached to $PUBLIC_BRIDGE."
    else
        echo
        echo "  [WARN] VM $VMID net0 does not appear to reference $PUBLIC_BRIDGE:"
        echo "         $NET0"
    fi
fi

section "Summary"
echo "Review any [FAIL] or [WARN] lines above."
echo "This script made no changes. See docs/troubleshooting.md for next steps."
