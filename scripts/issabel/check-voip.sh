#!/usr/bin/env bash
#
# check-voip.sh — Issabel 4 / Asterisk VoIP diagnostic (READ-ONLY)
#
# Checks the Asterisk service, listening SIP ports, RTP configuration,
# network connectivity, and recent relevant logs.
#
# This script does NOT change any firewall rules or SIP configuration.
# It is safe to run at any time.
#
# Run on: [ISABEL 4 CONSOLE]
# Usage:  bash scripts/issabel/check-voip.sh

set -uo pipefail

section() {
    echo
    echo "===================================================="
    echo "$1"
    echo "===================================================="
}

section "Asterisk service status"
if command -v systemctl >/dev/null 2>&1; then
    systemctl status asterisk --no-pager 2>&1 | head -n 10
    if systemctl is-active --quiet asterisk; then
        echo "  [OK] Asterisk service is active."
    else
        echo "  [FAIL] Asterisk service is not active."
    fi
else
    echo "  [WARN] systemctl not available."
fi

if ! command -v asterisk >/dev/null 2>&1; then
    echo
    echo "[WARN] 'asterisk' CLI not found on PATH — skipping CLI-based checks below."
    echo "This is expected if run outside the Issabel VM."
    exit 0
fi

section "Asterisk version"
asterisk -rx "core show version" 2>&1

section "SIP peers / trunks (chan_sip)"
asterisk -rx "sip show peers" 2>&1 || echo "  (chan_sip may not be in use — see PJSIP section below)"

section "SIP registration state (chan_sip)"
asterisk -rx "sip show registry" 2>&1 || true

section "PJSIP endpoints"
asterisk -rx "pjsip show endpoints" 2>&1 || echo "  (PJSIP may not be in use — see chan_sip section above)"

section "PJSIP registration state"
asterisk -rx "pjsip show registrations" 2>&1 || true

echo
echo "NOTE: Whichever of chan_sip / PJSIP actually returned your trunk"
echo "and/or extensions above is the driver in use on this system. See"
echo "docs/voip-configuration.md."

section "RTP configuration (as reported by Asterisk)"
asterisk -rx "core show settings" 2>&1 | grep -i -A2 rtp || \
    echo "  [WARN] Could not extract RTP settings from 'core show settings'."
echo
echo "Cross-check against the live config file if needed:"
echo "  cat /etc/asterisk/rtp.conf"
echo "Do NOT assume the 10000-20000 default — verify the actual range"
echo "before relying on it for firewall configuration."

section "Listening SIP ports"
if command -v netstat >/dev/null 2>&1; then
    netstat -tulpn 2>/dev/null | grep -i asterisk
else
    ss -tulpn 2>/dev/null | grep -i asterisk || true
fi

section "Network connectivity (quick check)"
ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1 && echo "  [OK] Internet reachable." || echo "  [WARN] Internet not reachable."

section "Recent Asterisk log entries (last 30 lines)"
if [ -f /var/log/asterisk/full ]; then
    tail -n 30 /var/log/asterisk/full
else
    echo "  [WARN] /var/log/asterisk/full not found — check the actual log path for this install."
fi

section "Summary"
echo "This script made NO changes to firewall rules or SIP/PJSIP configuration."
echo "See docs/sip-trunk.md, docs/rtp-and-firewall.md, and"
echo "runbooks/sip-registration-failure.md / runbooks/no-voip-audio.md"
echo "for how to act on what this script reported."
