#!/bin/bash
# =============================================================================
# Modul 09: Sudo-Härtung
# =============================================================================
# Sicherheitsziel: Privilegierte Operationen absichern und protokollieren.
#
# Massnahmen:
# - use_pty: Sudo-Befehle laufen in einem Pseudo-Terminal
#   Verhindert bestimmte Exploits, die ohne TTY funktionieren
#
# - logfile: Alle Sudo-Befehle werden in /var/log/sudo.log protokolliert
#   Ermöglicht forensische Analyse und Compliance-Nachweis
#
# - loglinelen=0: Keine Zeilenlängenbegrenzung im Log
#   Stellt vollständige Befehlsprotokollierung sicher
# =============================================================================

echo "[*] Sudo Hardening"

SUDOERS_D="/etc/sudoers.d/99-hardening"

# Sudo-Härtungsregeln in separater Datei (sauberer als sudoers direkt editieren)
cat <<EOF > "$SUDOERS_D"
# Pseudo-Terminal erzwingen - erschwert bestimmte Privilege-Escalation-Techniken
Defaults use_pty
# Vollständiges Logging aller Sudo-Befehle für Audit-Trail
Defaults logfile="/var/log/sudo.log"
# Keine Zeilenlängenbegrenzung - vollständige Befehlsprotokollierung
Defaults loglinelen=0
EOF

# Restriktive Berechtigungen für Sudoers-Dateien (440 = nur root lesbar)
chmod 440 "$SUDOERS_D"

echo "[+] Sudo Hardening aktiviert (use_pty + sudo.log)"