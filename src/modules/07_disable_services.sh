#!/bin/bash

echo "[*] Unnoetige Services deaktivieren (Attack Surface reduzieren)"

# Liste kann je nach Setup angepasst werden
SERVICES=(
  "avahi-daemon"
  "bluetooth"
  "cups"
)

for svc in "${SERVICES[@]}"; do
  if systemctl list-unit-files | grep -q "^${svc}\.service"; then
    systemctl disable --now "${svc}.service" >/dev/null 2>&1 || true
    echo "[+] Deaktiviert: $svc"
  else
    echo "[-] Nicht vorhanden: $svc"
  fi
done