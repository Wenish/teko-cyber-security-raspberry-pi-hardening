#!/bin/bash

SSH_CONFIG="/etc/ssh/sshd_config"

echo "[*] SSH Hardening"

# Safety-Check: Ist mindestens ein SSH Public Key fuer irgendeinen User vorhanden?
# (Wir suchen nach authorized_keys unter /home/* und /root)
FOUND_KEYS=$(find /home /root -maxdepth 3 -type f -name "authorized_keys" 2>/dev/null | wc -l)

if [ "$FOUND_KEYS" -lt 1 ]; then
  echo "[!] WARNUNG: Keine authorized_keys gefunden."
  echo "[!] Passwort-Login wird NICHT deaktiviert, um Aussperren zu vermeiden."
  echo "[!] Bitte zuerst SSH-Key einrichten und danach Script erneut ausfuehren."
else
  sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSH_CONFIG"
  echo "[+] PasswordAuthentication deaktiviert (Key-only)"
fi

# Immer sinnvolle SSH-Haertung (ohne dich auszusperren)
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSH_CONFIG"
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSH_CONFIG"
sed -i 's/^#\?MaxAuthTries.*/MaxAuthTries 3/' "$SSH_CONFIG"
sed -i 's/^#\?X11Forwarding.*/X11Forwarding no/' "$SSH_CONFIG"

# Keepalive / Timeout (gegen "ewig offene" Sessions)
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