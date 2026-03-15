#!/bin/bash
# =============================================================================
# Modul 06: Nginx Webserver mit TLS-Härtung
# =============================================================================
# Sicherheitsziel: Sichere HTTPS-Auslieferung mit modernen Security-Headern.
#
# Security-Header schützen gegen:
# - X-Frame-Options DENY: Verhindert Clickjacking-Angriffe
# - X-Content-Type-Options nosniff: Verhindert MIME-Type-Sniffing
# - Referrer-Policy strict-origin: Begrenzt Informationsleck via Referrer
# - Content-Security-Policy: Begrenzt Ressourcenquellen gegen XSS
#
# TLS-Konfiguration:
# - Nur TLS 1.2 und 1.3: Ältere Versionen haben bekannte Schwachstellen
# - Server-Ciphers bevorzugt: Verhindert Downgrade-Angriffe
# =============================================================================

echo "[*] Nginx + TLS vorbereiten"

apt install -y nginx

# Security-Header-Snippet für Einbindung in Server-Blöcke
# Diese Header erhöhen die Client-seitige Sicherheit erheblich
cat <<EOF > /etc/nginx/snippets/security.conf
# Clickjacking-Schutz: Seite darf nicht in Frames eingebettet werden
add_header X-Frame-Options DENY;
# MIME-Sniffing verhindern: Browser soll Content-Type vertrauen
add_header X-Content-Type-Options nosniff;
# Referrer-Informationen begrenzen: Nur Origin bei Cross-Origin-Requests
add_header Referrer-Policy strict-origin;
# Content-Security-Policy: Nur HTTPS-Ressourcen erlauben
add_header Content-Security-Policy "default-src https: data: 'unsafe-inline'";
EOF

# TLS-Konfiguration: Nur moderne, sichere Protokollversionen
cat <<EOF > /etc/nginx/snippets/ssl.conf
# Nur TLS 1.2 und 1.3 erlauben (TLS 1.0/1.1 sind unsicher)
ssl_protocols TLSv1.2 TLSv1.3;
# Server bestimmt Cipher-Reihenfolge (verhindert Client-seitige Downgrade-Angriffe)
ssl_prefer_server_ciphers on;
EOF

echo "[✓] Nginx + TLS Vorbereitung abgeschlossen"