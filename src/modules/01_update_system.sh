#!/usr/bin/env bash
# =============================================================================
# Modul 01: Systemaktualisierung und automatische Sicherheitsupdates
# =============================================================================
# Sicherheitsziel: Bekannte Schwachstellen zeitnah patchen.
# Ungepatchte Systeme sind das häufigste Einfallstor für Angreifer.
# Unattended-Upgrades stellt sicher, dass kritische Patches automatisch
# eingespielt werden - wichtig für Headless-Systeme wie Raspberry Pi.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/00_common.sh"
ensure_root

log "Systemupdate"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Automatische Sicherheitsupdates konfigurieren
# - unattended-upgrades: Installiert Sicherheitsupdates automatisch
# - apt-listchanges: Informiert über Änderungen in aktualisierten Paketen
apt_install unattended-upgrades apt-listchanges

# dpkg-reconfigure ist Teil des debconf-Pakets
# Wird für nicht-interaktive Konfiguration benötigt
ensure_cmd_or_pkg dpkg-reconfigure debconf

# Aktiviert automatische Sicherheitsupdates ohne Benutzerinteraktion
# Kritisch für Systeme ohne regelmäßige manuelle Wartung
dpkg-reconfigure -f noninteractive unattended-upgrades || true

ok "Systemupdate abgeschlossen"