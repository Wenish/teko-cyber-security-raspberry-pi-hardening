#!/bin/bash
# =============================================================================
# Modul 11: Persistentes System-Logging
# =============================================================================
# Sicherheitsziel: Forensische Analyse und Incident Response ermöglichen.
#
# Journald-Konfiguration:
# - Storage=persistent: Logs überleben Neustarts (Standard: flüchtig)
#   Kritisch für forensische Analyse nach Zwischenfällen
#
# - SystemMaxUse=200M: Begrenzt Speicherverbrauch
#   Wichtig für Systeme mit begrenztem SD-Karten-Speicher
#   Verhindert auch Log-Flooding-Angriffe (Disk Exhaustion)
# =============================================================================

echo "[*] Logging verbessern (journald persistent)"

# Verzeichnis für persistente Logs anlegen
mkdir -p /var/log/journal

JOURNALD_CONF="/etc/systemd/journald.conf"

# Persistentes Logging aktivieren - Logs überleben Neustarts
# Ermöglicht forensische Analyse nach Sicherheitsvorfällen
if grep -q "^#\?Storage=" "$JOURNALD_CONF"; then
  sed -i 's/^#\?Storage=.*/Storage=persistent/' "$JOURNALD_CONF"
else
  echo "Storage=persistent" >> "$JOURNALD_CONF"
fi

# Log-Größe begrenzen - Schutz vor Disk-Exhaustion und SD-Karten-Schonung
# 200MB ist ein guter Kompromiss zwischen Historie und Speicherverbrauch
if grep -q "^#\?SystemMaxUse=" "$JOURNALD_CONF"; then
  sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=200M/' "$JOURNALD_CONF"
else
  echo "SystemMaxUse=200M" >> "$JOURNALD_CONF"
fi

systemctl restart systemd-journald
echo "[+] journald persistent aktiviert"