#!/usr/bin/env bash
# =============================================================================
# Modul 99: Verifizierung der Hardening-Massnahmen
# =============================================================================
# Sicherheitsziel: Bestätigung der korrekten Konfiguration.
#
# Prüft die wichtigsten Hardening-Einstellungen:
# - SSH: Passwort-Login und Root-Zugang Status
# - Firewall: Aktive UFW-Regeln anzeigen
# - Fail2Ban: Status des SSH-Jails
#
# Dient als Schnellübersicht nach Abschluss des Hardenings.
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/00_common.sh"
ensure_root

log "Verifikation"

echo "--- SSH ---"
if have_cmd sshd; then
  sshd -T | egrep "passwordauthentication|permitrootlogin" || true
else
  warn "sshd nicht im PATH / nicht installiert"
fi

echo "--- Firewall ---"
if have_cmd ufw; then
  ufw status verbose || true
else
  warn "ufw nicht im PATH / nicht installiert"
fi

echo "--- Fail2Ban ---"
if have_cmd fail2ban-client; then
  fail2ban-client status sshd || true
else
  warn "fail2ban-client nicht gefunden"
fi

ok "Verifikation abgeschlossen"