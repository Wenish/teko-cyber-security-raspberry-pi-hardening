#!/bin/bash
# =============================================================================
# Modul 07: Deaktivierung unnötiger Dienste
# =============================================================================
# Sicherheitsziel: Angriffsfläche minimieren (Attack Surface Reduction).
#
# Jeder laufende Dienst ist ein potentielles Angriffsziel. Dienste, die nicht
# benötigt werden, sollten deaktiviert werden:
#
# - avahi-daemon: mDNS/Zeroconf - Service-Discovery im lokalen Netz
#   Risiko: Informationsleck über verfügbare Dienste, Spoofing-Angriffe
#
# - bluetooth: Bluetooth-Stack
#   Risiko: Proximity-basierte Angriffe (BlueBorne, BlueSmack)
#
# - cups: Druckserver
#   Risiko: Historisch viele Schwachstellen, unnötig auf Headless-Systemen
# =============================================================================

echo "[*] Unnoetige Services deaktivieren (Attack Surface reduzieren)"

# Zu deaktivierende Dienste - kann je nach Anforderungen angepasst werden
# WICHTIG: Nur Dienste deaktivieren, die tatsächlich nicht benötigt werden!
SERVICES=(
  "avahi-daemon"   # mDNS Service Discovery - unnötig auf Servern
  "bluetooth"      # Bluetooth-Stack - Risiko bei physischem Zugang
  "cups"           # Druckserver - unnötig auf Headless-Systemen
)

for svc in "${SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^${svc}\.service"; then
    systemctl disable --now "${svc}.service" >/dev/null 2>&1 || true
    echo "[+] Deaktiviert: $svc"
  else
    echo "[-] Nicht vorhanden: $svc"
  fi
done