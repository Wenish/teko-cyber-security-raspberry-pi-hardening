#!/bin/bash

echo "[*] Logging verbessern (journald persistent)"

mkdir -p /var/log/journal

JOURNALD_CONF="/etc/systemd/journald.conf"

# Storage=persistent setzen (oder ersetzen)
if grep -q "^#\?Storage=" "$JOURNALD_CONF"; then
  sed -i 's/^#\?Storage=.*/Storage=persistent/' "$JOURNALD_CONF"
else
  echo "Storage=persistent" >> "$JOURNALD_CONF"
fi

# Optional: Log-Groesse begrenzen (sauber fuer SD-Karte)
if grep -q "^#\?SystemMaxUse=" "$JOURNALD_CONF"; then
  sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=200M/' "$JOURNALD_CONF"
else
  echo "SystemMaxUse=200M" >> "$JOURNALD_CONF"
fi

systemctl restart systemd-journald
echo "[+] journald persistent aktiviert"