#!/usr/bin/env bash
#
# check-network.sh — Issabel 4 (VM 200) network diagnostic (READ-ONLY)
#
# Checks eth0, IP address, default route, gateway connectivity,
# internet connectivity, DNS, and the HTTP service.
#
# This script makes NO changes to the system. It is safe to run at
# any time.
#
# Run on: [ISABEL 4 CONSOLE]
# Usage:  bash scripts/issabel/check-network.sh

set -uo pipefail

IFACE="eth0"
EXPECTED_IP="61.245.30.75"
EXPECTED_PREFIX="29"
GATEWAY="61.245.30.73"

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

section "Interface: $IFACE"
if ip link show "$IFACE" >/dev/null 2>&1; then
    ip -br addr show "$IFACE"
    ethtool "$IFACE" 2>/dev/null | grep "Link detected"
    LINK=$(ethtool "$IFACE" 2>/dev/null | grep "Link detected" | awk '{print $3}')
    if [ "$LINK" = "yes" ]; then
        echo "  [OK] Link detected on $IFACE."
    else
        echo "  [FAIL] No link detected on $IFACE."
        echo "         Check the Proxmox-side bridge/VM attachment first"
        echo "         (see docs/proxmox-setup.md / issabel4-installation.md)."
    fi
else
    echo "  [FAIL] Interface $IFACE not found."
fi

section "IP Address"
CURRENT_IP=$(ip -br addr show "$IFACE" 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
CURRENT_PREFIX=$(ip -br addr show "$IFACE" 2>/dev/null | awk '{print $3}' | cut -d/ -f2)
echo "  Current: ${CURRENT_IP:-none}/${CURRENT_PREFIX:-?}"
echo "  Expected: $EXPECTED_IP/$EXPECTED_PREFIX"
if [ "$CURRENT_IP" = "$EXPECTED_IP" ] && [ "$CURRENT_PREFIX" = "$EXPECTED_PREFIX" ]; then
    echo "  [OK] IP address matches documented configuration."
else
    echo "  [WARN] IP address does not match documented configuration."
    echo "         See docs/issabel-networking.md."
fi

section "Default Route"
ip route | grep '^default' || echo "  [FAIL] No default route found."
if ip route | grep -q "^default via $GATEWAY"; then
    echo "  [OK] Default route via expected gateway ($GATEWAY)."
else
    echo "  [WARN] Default route does not match expected gateway ($GATEWAY)."
fi

section "Gateway Connectivity"
if ping -c 2 -W 2 "$GATEWAY" >/dev/null 2>&1; then
    echo "  [OK] Gateway $GATEWAY is reachable."
else
    echo "  [FAIL] Gateway $GATEWAY is NOT reachable."
    echo "         See runbooks/public-ip-failure.md."
fi

section "Internet Connectivity"
if ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
    echo "  [OK] 8.8.8.8 is reachable."
else
    echo "  [FAIL] 8.8.8.8 is NOT reachable (internet routing problem upstream)."
fi

section "DNS Resolution"
if ping -c 2 -W 2 google.com >/dev/null 2>&1; then
    echo "  [OK] DNS resolution + internet reachability confirmed via google.com."
else
    echo "  [WARN] Could not reach google.com — check DNS (DNS1/DNS2 in ifcfg-eth0)"
    echo "         or internet routing."
fi

section "HTTP Service"
if command -v curl >/dev/null 2>&1; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 3 http://127.0.0.1 || echo "000")
    echo "  Local HTTP response code: $HTTP_CODE"
    if [ "$HTTP_CODE" != "000" ]; then
        echo "  [OK] Local web server is responding."
    else
        echo "  [WARN] Local web server did not respond. Check 'systemctl status httpd'."
    fi
else
    echo "  [WARN] curl not available — skipping HTTP check."
fi

section "Summary"
echo "Review any [FAIL] or [WARN] lines above."
echo "This script made no changes. See docs/troubleshooting.md for next steps."
