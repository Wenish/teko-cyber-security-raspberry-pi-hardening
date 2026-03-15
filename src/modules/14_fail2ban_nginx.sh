#!/bin/bash
# =============================================================================
# Modul 14: Fail2Ban für Nginx - Web Application Firewall
# =============================================================================
# Sicherheitsziel: Automatische Blockierung von Web-Angriffen.
#
# Der nginx-badbots Jail erkennt und blockiert:
# - Automatisierte Scanner und Vulnerability-Scanner
# - Bots, die nach bekannten Schwachstellen suchen (404er)
# - Brute-Force auf Login-Seiten
# - Directory-Traversal-Versuche
#
# Trigger: Zu viele 403/404/444-Fehler innerhalb kurzer Zeit
# deuten auf Reconnaissance oder Exploitation hin.
# =============================================================================

echo "[*] Fail2Ban fuer Nginx aktivieren"

# Prüfe Voraussetzungen - Fail2Ban und Nginx müssen installiert sein
if ! command -v fail2ban-client >/dev/null 2>&1; then
  echo "[-] fail2ban nicht installiert, ueberspringe"
  exit 0
fi

if ! command -v nginx >/dev/null 2>&1; then
  echo "[-] nginx nicht installiert, ueberspringe"
  exit 0
fi

# Nginx Access-Log muss existieren für Log-Analyse
NGINX_ACCESS="/var/log/nginx/access.log"
if [ ! -f "$NGINX_ACCESS" ]; then
  echo "[-] Kein Nginx access.log gefunden ($NGINX_ACCESS). Ueberspringe."
  exit 0
fi

JAIL_LOCAL="/etc/fail2ban/jail.local"

# Lokale jail.local sicherstellen (falls nicht durch Modul 04 erstellt)
if [ ! -f "$JAIL_LOCAL" ]; then
  touch "$JAIL_LOCAL"
fi

# Nginx-Jail konfigurieren für Bad-Bot-Erkennung
# 10 Fehlversuche in 10 Minuten führen zu 1h Bann
if ! grep -q "^\[nginx-badbots\]" "$JAIL_LOCAL"; then
  cat <<EOF >> "$JAIL_LOCAL"

# =============================================================================
# Nginx Bad Bots Jail - Web Scanner und Exploit-Versuche blockieren
# =============================================================================
[nginx-badbots]
enabled = true
port    = http,https
filter  = nginx-badbots
logpath = /var/log/nginx/access.log
# Schwellwert: 10 verdächtige Anfragen in 10 Minuten = Bann
maxretry = 10
findtime = 10m
# Bannzeit: 1 Stunde - lang genug um automatisierte Scans zu stoppen
bantime  = 1h
EOF
  echo "[+] jail nginx-badbots hinzugefuegt"
else
  echo "[-] nginx-badbots jail existiert bereits"
fi

# Filter-Definition für nginx-badbots
# Erkennt HTTP-Statuscodes die auf Angriffe hindeuten:
# - 403 Forbidden: Zugriffsversuche auf geschützte Ressourcen
# - 404 Not Found: Scanner suchen nach bekannten Schwachstellen
# - 444 Connection Closed: Nginx-spezifisch für abgewiesene Anfragen
FILTER="/etc/fail2ban/filter.d/nginx-badbots.conf"
cat <<'EOF' > "$FILTER"
[Definition]
# Regex: Matcht verdächtige HTTP-Anfragen anhand des Statuscodes
# IPs mit vielen 403/404/444 werden als Scanner klassifiziert
failregex = ^<HOST> - .* "(GET|POST|HEAD).*" (403|404|444) .*
ignoreregex =
EOF

systemctl restart fail2ban
echo "[+] Fail2Ban neu gestartet (Nginx Jail aktiv)"