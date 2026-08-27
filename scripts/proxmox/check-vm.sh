#!/usr/bin/env bash
#
# check-vm.sh — Proxmox VM 200 (Issabel4) status diagnostic (READ-ONLY)
#
# Checks that VM 200 exists, is running, and its configuration matches
# the documented specification.
#
# This script makes NO changes to the system. It is safe to run at
# any time.
#
# Run on: [PROXMOX HOST]
# Usage:  bash scripts/proxmox/check-vm.sh

set -uo pipefail

VMID="200"
EXPECTED_BRIDGE="vmbr1"
EXPECTED_MAC="BC:24:11:3F:23:CC"

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

if ! command -v qm >/dev/null 2>&1; then
    echo "[FAIL] 'qm' command not found. Run this script on the Proxmox host."
    exit 1
fi

section "VM $VMID status"
qm status "$VMID"
STATUS_OUT=$(qm status "$VMID" 2>/dev/null)
if echo "$STATUS_OUT" | grep -q "status: running"; then
    echo "  [OK] VM $VMID is running."
else
    echo "  [WARN] VM $VMID does not appear to be running."
fi

section "VM $VMID full configuration"
CONFIG_OUT=$(qm config "$VMID" 2>/dev/null)
echo "$CONFIG_OUT"

echo
echo "Checking key configuration values against documented spec:"

NET0_LINE=$(echo "$CONFIG_OUT" | grep '^net0:')
if echo "$NET0_LINE" | grep -q "bridge=$EXPECTED_BRIDGE"; then
    echo "  [OK] net0 is attached to $EXPECTED_BRIDGE."
else
    echo "  [WARN] net0 does not reference $EXPECTED_BRIDGE as expected:"
    echo "         $NET0_LINE"
fi

if echo "$NET0_LINE" | grep -qi "$EXPECTED_MAC"; then
    echo "  [OK] MAC address matches documented value ($EXPECTED_MAC)."
else
    echo "  [WARN] MAC address does not match documented value ($EXPECTED_MAC):"
    echo "         $NET0_LINE"
fi

if echo "$NET0_LINE" | grep -q "firewall=1"; then
    echo "  [OK] Firewall is enabled on net0."
else
    echo "  [WARN] Firewall does not appear to be enabled on net0:"
    echo "         $NET0_LINE"
fi

CORES=$(echo "$CONFIG_OUT" | grep '^cores:' | awk '{print $2}')
MEMORY=$(echo "$CONFIG_OUT" | grep '^memory:' | awk '{print $2}')
echo "  Cores: ${CORES:-unknown} (expected: 2)"
echo "  Memory: ${MEMORY:-unknown} MB (expected: 4096)"

section "Summary"
echo "Review any [WARN] lines above against docs/issabel4-installation.md."
echo "This script made no changes."
