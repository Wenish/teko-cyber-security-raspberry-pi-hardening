#!/bin/bash

echo "[*] Nginx Rate Limiting konfigurieren"

# Nur wenn nginx installiert ist
if ! command -v nginx >/dev/null 2>&1; then
  echo "[-] nginx nicht installiert, ueberspringe"
  exit 0
fi

CONF="/etc/nginx/conf.d/99-hardening-rate-limit.conf"

cat <<'EOF' > "$CONF"
# Simple Rate Limits (global)
# 10 requests/sec pro IP, burst 20
limit_req_zone $binary_remote_addr zone=req_per_ip:10m rate=10r/s;

# 20 gleichzeitige Verbindungen pro IP
limit_conn_zone $binary_remote_addr zone=conn_per_ip:10m;

# Diese Einstellungen werden in server{} Bloecken per include angewendet,
# oder wenn dein Default-Site sie einbindet.
EOF

# In default site einhaengen, falls vorhanden und noch nicht enthalten
DEFAULT_SITE="/etc/nginx/sites-available/default"
if [ -f "$DEFAULT_SITE" ]; then
  if ! grep -q "99-hardening-rate-limit.conf" "$DEFAULT_SITE"; then
    # Wir fuegen die Anwendung der Limits in den server{} Block ein (direkt nach "server {")
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