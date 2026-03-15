#!/bin/bash
# =============================================================================
# Modul 13: Nginx Rate Limiting
# =============================================================================
# Sicherheitsziel: Schutz vor DoS-Angriffen und Ressourcenerschöpfung.
#
# Rate Limiting begrenzt Anfragen pro IP und Zeit:
# - limit_req_zone (10r/s): Max 10 Requests pro Sekunde pro IP
#   Schützt vor HTTP-Flood und Brute-Force auf Webanwendungen
#
# - limit_conn_zone (20): Max 20 gleichzeitige Verbindungen pro IP
#   Verhindert Slowloris-artige Angriffe und Ressourcenblockierung
#
# Burst=20 erlaubt kurze Lastspitzen (z.B. initiales Laden einer Seite)
# ohne legitime Nutzer zu blockieren.
# =============================================================================

echo "[*] Nginx Rate Limiting konfigurieren"

# Nur wenn nginx installiert ist
if ! command -v nginx >/dev/null 2>&1; then
  echo "[-] nginx nicht installiert, ueberspringe"
  exit 0
fi

CONF="/etc/nginx/conf.d/99-hardening-rate-limit.conf"

# Rate-Limiting-Zonen definieren (global für alle Server-Blöcke verfügbar)
cat <<'EOF' > "$CONF"
# =============================================================================
# Rate Limiting Konfiguration - DoS-Schutz
# =============================================================================

# Request-Rate-Limit: Max 10 Anfragen/Sekunde pro IP
# Zone-Größe 10MB speichert ca. 160.000 IP-Adressen
limit_req_zone $binary_remote_addr zone=req_per_ip:10m rate=10r/s;

# Connection-Limit: Max 20 gleichzeitige Verbindungen pro IP
# Schützt vor Slowloris und Connection-Exhaustion-Angriffen
limit_conn_zone $binary_remote_addr zone=conn_per_ip:10m;

# Anwendung in Server-Blöcken:
# limit_req zone=req_per_ip burst=20 nodelay;
# limit_conn conn_per_ip 20;
EOF

# Rate Limiting in Default-Site aktivieren (falls vorhanden)
# Hardening-Regeln werden direkt nach 'server {' eingefügt
DEFAULT_SITE="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_SITE" ]; then
  if ! grep -q "99-hardening-rate-limit.conf" "$DEFAULT_SITE"; then
    # Burst=20 erlaubt kurze Lastspitzen, nodelay verarbeitet diese sofort
    sed -i '/server {/a\\n    # Hardening: Rate limiting / connection limiting\n    limit_req zone=req_per_ip burst=20 nodelay;\n    limit_conn conn_per_ip 20;\n' "$DEFAULT_SITE"
    echo "[+] Rate limits in default site aktiviert"
  else
    echo "[-] default site bereits angepasst"
  fi
else
  echo "[-] default site nicht gefunden, bitte manuell in deinen server{} Block setzen:"
  echo "    limit_req zone=req_per_ip burst=20 nodelay;"
  echo "    limit_conn conn_per_ip 20;"
fi

nginx -t
systemctl reload nginx
echo "[+] Nginx neu geladen"