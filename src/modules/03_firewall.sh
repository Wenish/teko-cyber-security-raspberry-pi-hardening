#!/usr/bin/env bash
# =============================================================================
# Modul 03: Firewall-Konfiguration (UFW)
# =============================================================================
# Sicherheitsziel: Netzwerk-Segmentierung durch Paketfilterung.
#
# Prinzip: Default Deny - nur explizit erlaubte Verbindungen werden zugelassen.
# Dies minimiert die Angriffsfläche drastisch, da ungenutzete Dienste nicht
# über das Netzwerk erreichbar sind, selbst wenn sie laufen.
#
# Erlaubte Ports:
# - 22/tcp: SSH (Remote-Administration)
# - 80/tcp: HTTP (Weiterleitung auf HTTPS)
# - 443/tcp: HTTPS (Verschlüsselte Webdienste)
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/00_common.sh"
ensure_root

log "Firewall (UFW) konfigurieren"

ensure_cmd_or_pkg ufw ufw

# Default-Policy: Eingehend blockieren, ausgehend erlauben
# Nur explizit definierte Dienste sind erreichbar
ufw default deny incoming
ufw default allow outgoing

# SSH-Zugang sicherstellen (Administration)
ufw allow 22/tcp

# Webserver-Ports für HTTPS-Dienste
ufw allow 80/tcp
ufw allow 443/tcp

# Firewall aktivieren (--force für nicht-interaktive Ausführung)
ufw --force enable

ok "Firewall Konfiguration abgeschlossen"