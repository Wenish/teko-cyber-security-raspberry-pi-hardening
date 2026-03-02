#!/bin/bash

echo "[*] Fail2Ban fuer Nginx aktivieren"

# fail2ban muss vorhanden sein (dein 04er Modul installiert es)
if ! command -v fail2ban-client >/dev/null 2>&1; then
  echo "[-] fail2ban nicht installiert, ueberspringe"
  exit 0
fi

# nginx muss vorhanden sein
if ! command -v nginx >/dev/null 2>&1; then
  echo "[-] nginx nicht installiert, ueberspringe"
  exit 0
fi

# Stelle sicher, dass access.log existiert (default nginx)
NGINX_ACCESS="/var/log/nginx/access.log"
if [ ! -f "$NGINX_ACCESS" ]; then
  echo "[-] Kein Nginx access.log gefunden ($NGINX_ACCESS). Ueberspringe."
  exit 0
fi

JAIL_LOCAL="/etc/fail2ban/jail.local"

# Wenn jail.local nicht existiert, legen wir es an (dein 04er macht es zwar, aber sicher ist sicher)
if [ ! -f "$JAIL_LOCAL" ]; then
  touch "$JAIL_LOCAL"
fi

# Nginx jail anhaengen, wenn noch nicht vorhanden
if ! grep -q "^\[nginx-badbots\]" "$JAIL_LOCAL"; then
  cat <<EOF >> "$JAIL_LOCAL"

[nginx-badbots]
enabled = true
port    = http,https
filter  = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 10
findtime = 10m
bantime  = 1h
EOF
  echo "[+] jail nginx-badbots hinzugefuegt"
else
  echo "[-] nginx-badbots jail existiert bereits"
fi

# Filter definieren (einfach, robust)
FILTER="/etc/fail2ban/filter.d/nginx-badbots.conf"
cat <<'EOF' > "$FILTER"
[Definition]
# Ban wenn zu viele 404/444/403 von derselben IP innerhalb kurzer Zeit auftreten
failregex = ^<HOST> - .* "(GET|POST|HEAD).*" (403|404|444) .*
ignoreregex =
EOF

systemctl restart fail2ban
echo "[+] Fail2Ban neu gestartet (Nginx Jail aktiv)"