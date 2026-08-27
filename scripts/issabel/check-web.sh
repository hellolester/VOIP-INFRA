#!/usr/bin/env bash
#
# check-web.sh — Issabel 4 web management diagnostic (READ-ONLY)
#
# Checks the httpd service, listening ports, and local HTTP response.
#
# This script makes NO changes to the system. It is safe to run at
# any time.
#
# Run on: [ISABEL 4 CONSOLE]
# Usage:  bash scripts/issabel/check-web.sh

set -uo pipefail

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

section "httpd service status"
if command -v systemctl >/dev/null 2>&1; then
    systemctl status httpd --no-pager 2>&1 | head -n 10
    if systemctl is-active --quiet httpd; then
        echo "  [OK] httpd is active."
    else
        echo "  [FAIL] httpd is not active."
    fi
else
    echo "  [WARN] systemctl not available."
fi

section "Listening ports (80/443)"
if command -v netstat >/dev/null 2>&1; then
    LISTEN=$(netstat -tulpn 2>/dev/null | grep -E ':80|:443')
    if [ -n "$LISTEN" ]; then
        echo "$LISTEN"
        echo "  [OK] Something is listening on port 80 and/or 443."
    else
        echo "  [FAIL] Nothing listening on port 80 or 443."
    fi
else
    echo "  [WARN] netstat not available — try 'ss -tulpn' manually."
    ss -tulpn 2>/dev/null | grep -E ':80|:443' || true
fi

section "Local HTTP response"
if command -v curl >/dev/null 2>&1; then
    echo "HTTP (port 80):"
    curl -I -m 3 http://127.0.0.1 2>&1 | head -n 5
    echo
    echo "HTTPS (port 443, if configured):"
    curl -I -k -m 3 https://127.0.0.1 2>&1 | head -n 5
else
    echo "  [WARN] curl not available — skipping."
fi

section "Summary"
echo "If local checks pass but the site is unreachable externally,"
echo "the issue is likely firewall/network, not the web server itself."
echo "See docs/web-management.md and runbooks/web-management-failure.md."
echo "This script made no changes."
