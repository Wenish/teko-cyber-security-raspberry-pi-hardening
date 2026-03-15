#!/bin/bash
# =============================================================================
# Modul 04: Fail2Ban - Intrusion Prevention System
# =============================================================================
# Sicherheitsziel: Automatische Abwehr von Brute-Force-Angriffen.
#
# Fail2Ban analysiert Log-Dateien und erkennt fehlgeschlagene Login-Versuche.
# Nach Überschreiten des Schwellwerts wird die Angreifer-IP temporär gebannt.
#
# Konfiguration:
# - bantime 1h: Angreifer-IP wird für 1 Stunde blockiert
# - findtime 10m: Zeitfenster für Versuchszählung
# - maxretry 3: Nach 3 Fehlversuchen erfolgt Bann
#
# Dies erschwert automatisierte Angriffe erheblich, da Angreifer nach
# wenigen Versuchen eine Stunde warten müssten.
# =============================================================================

echo "[*] Fail2Ban installieren"

apt install -y fail2ban

# Lokale Konfiguration überschreibt Defaults und überlebt Updates
cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
# Bannzeit: Blockiert Angreifer für 1 Stunde
bantime = 1h
# Zeitfenster für die Zählung der Fehlversuche
findtime = 10m
# Maximale Fehlversuche bevor IP gebannt wird
maxretry = 3

[sshd]
# SSH-Jail aktivieren - schützt vor SSH-Brute-Force
enabled = true
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo "[✓] Fail2Ban Installation abgeschlossen"