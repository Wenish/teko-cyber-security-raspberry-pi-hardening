#!/usr/bin/env bash
# =============================================================================
# Modul 05: Kernel- und Netzwerk-Härtung (sysctl)
# =============================================================================
# Sicherheitsziel: Netzwerk-Stack gegen typische Angriffe absichern.
#
# Diese Kernel-Parameter schützen gegen:
# - IP-Spoofing (rp_filter): Pakete werden nur akzeptiert, wenn die
#   Absenderadresse über das Empfangsinterface erreichbar ist
# - Source-Routing-Angriffe: Verhindert, dass Angreifer den Paketweg manipulieren
# - ICMP-Redirect-Angriffe: Verhindert Routing-Manipulation durch gefälschte ICMP
# - SYN-Flood-Attacken: TCP SYN-Cookies schützen vor Ressourcenerschöpfung
# - IPv6-Angriffe: Deaktivierung wenn nicht genutzt reduziert Angriffsfläche
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/00_common.sh"
ensure_root

log "Kernel & Netzwerk Hardening"

ensure_cmd_or_pkg sysctl procps

SYSCTL_FILE="/etc/sysctl.d/99-hardening.conf"

cat > "$SYSCTL_FILE" <<'EOF'
# =============================================================================
# IP-Spoofing-Schutz (Reverse Path Filtering)
# Pakete werden verworfen, wenn die Quelladresse nicht über das Empfangsinterface
# erreichbar ist. Verhindert IP-Adress-Fälschung.
# =============================================================================
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# =============================================================================
# Source-Routing deaktivieren
# Verhindert, dass Angreifer den Paketweg manipulieren können.
# Source-Routing wird legitim fast nie benötigt.
# =============================================================================  
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0

# =============================================================================
# ICMP-Redirect-Schutz
# Verhindert Routing-Manipulation durch gefälschte ICMP-Redirect-Pakete.
# Angreifer könnten sonst Traffic umleiten (Man-in-the-Middle).
# =============================================================================
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# =============================================================================
# SYN-Flood-Schutz (SYN Cookies)
# Bei Überlastung werden SYN-Cookies verwendet statt Speicherreservierung.
# Schützt vor Denial-of-Service durch halboffene TCP-Verbindungen.
# =============================================================================
net.ipv4.tcp_syncookies=1

# =============================================================================
# IPv6 deaktivieren (falls nicht benötigt)
# Reduziert Angriffsfläche bei reinen IPv4-Umgebungen.
# Bei IPv6-Nutzung diese Zeilen entfernen!
# =============================================================================
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
EOF

sysctl --system >/dev/null

ok "Kernel & Netzwerk Hardening abgeschlossen"