#!/bin/bash
# =============================================================================
# Modul 02: SSH-Härtung
# =============================================================================
# Sicherheitsziel: SSH ist der Hauptzugangsvektor - muss maximal geschützt werden.
#
# Massnahmen:
# - Passwort-Auth deaktivieren: Verhindert Brute-Force-Angriffe auf Passwörter
# - Root-Login verbieten: Erzwingt Nutzung von unprivilegierten Accounts + sudo
# - MaxAuthTries begrenzen: Erschwert Brute-Force durch schnelle Sperre
# - X11-Forwarding deaktivieren: Reduziert Angriffsfläche (unnötige Funktion)
# - Session-Timeout: Schliesst inaktive Sessions (gegen Session-Hijacking)
# =============================================================================

SSH_CONFIG="/etc/ssh/sshd_config"

# Sicherheitsprüfung: Mindestens ein SSH-Key muss vorhanden sein
# Verhindert Aussperren bei Deaktivierung der Passwort-Authentifizierung
FOUND_KEYS=$(find /home /root -maxdepth 3 -type f -name "authorized_keys" 2>/dev/null | wc -l)

if [ "$FOUND_KEYS" -lt 1 ]; then
  echo "[!] WARNUNG: Keine authorized_keys gefunden."
  echo "[!] Passwort-Login wird NICHT deaktiviert, um Aussperren zu vermeiden."
  echo "[!] Bitte zuerst SSH-Key einrichten und danach Script erneut ausfuehren."
else
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
  echo "[+] PasswordAuthentication deaktiviert (Key-only)"
fi

# Grundlegende SSH-Härtungsparameter (immer anwenden)
# PermitRootLogin no: Angreifer müssen zuerst einen normalen User kompromittieren
# PubkeyAuthentication yes: Kryptographisch sichere Authentifizierung aktivieren  
# MaxAuthTries 3: Begrenzt Brute-Force-Versuche pro Verbindung
# X11Forwarding no: X11-Weiterleitung ist unnötig und potentieller Angriffsvektor
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"

# Session-Keepalive und Timeout-Konfiguration
# ClientAliveInterval 300: Server pingt Client alle 5 Minuten
# ClientAliveCountMax 2: Nach 2 fehlgeschlagenen Pings wird Session beendet
# Effekt: Inaktive Sessions werden nach ca. 10 Min getrennt (gegen Session-Hijacking)
if ! grep -q "^ClientAliveInterval" "$SSH_CONFIG"; then
  echo "ClientAliveInterval 300" >> "$SSH_CONFIG"
else
  sed -i 's/^#\?ClientAliveInterval.*/ClientAliveInterval 300/' "$SSH_CONFIG"
fi

if ! grep -q "^ClientAliveCountMax" "$SSH_CONFIG"; then
  echo "ClientAliveCountMax 2" >> "$SSH_CONFIG"
else
  sed -i 's/^#\?ClientAliveCountMax.*/ClientAliveCountMax 2/' "$SSH_CONFIG"
fi

systemctl restart ssh
echo "[+] SSH neu gestartet"
echo "[✓] SSH Hardening abgeschlossen"