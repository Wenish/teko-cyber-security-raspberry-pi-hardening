#!/bin/bash
# =============================================================================
# Hardening-Verifizierungsskript
# =============================================================================
# Prüft die korrekte Umsetzung der Sicherheitsmaßnahmen.
# Score-basierte Bewertung zur schnellen Übersicht des Härtungsstands.
# =============================================================================

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "========================================"
echo "   Debian 13.3 Hardening Check"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
  echo "[!] Bitte als root ausfuehren (sudo ./check.sh)"
  exit 1
fi

NETWORK_CHECK=false
if [ "$1" == "--network" ]; then
  NETWORK_CHECK=true
fi

SCORE=0
MAX_SCORE=10

echo
echo "[1] SSH Passwort-Login deaktiviert"
# Passwort-Authentifizierung ist anfällig für Brute-Force-Angriffe.
# SSH-Keys bieten kryptographisch starke Authentifizierung.
if command -v sshd >/dev/null 2>&1; then
  if sshd -T 2>/dev/null | grep -q "passwordauthentication no"; then
    echo "[+] OK"
    SCORE=$((SCORE+1))
  else
    echo "[!] NICHT deaktiviert"
  fi
else
  echo "[-] sshd nicht installiert, überspringe"
fi

echo
echo "[2] Root-Login deaktiviert"
# Direkter Root-Zugang erhöht das Risiko bei kompromittierten Credentials.
# Loginversuche via normalem User + sudo ermöglichen bessere Nachverfolgung.
if command -v sshd >/dev/null 2>&1; then
  if sshd -T 2>/dev/null | grep -q "permitrootlogin no"; then
    echo "[+] OK"
    SCORE=$((SCORE+1))
  else
    echo "[!] Root-Login erlaubt"
  fi
else
  echo "[-] sshd nicht installiert, überspringe"
fi

echo
echo "[3] UFW aktiv"
# Die Firewall begrenzt eingehende Verbindungen auf explizit erlaubte Ports.
# Reduziert die Angriffsfläche durch Blockieren unnötiger Netzwerkdienste.
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] UFW nicht aktiv oder nicht installiert"
fi

echo
echo "[4] Nur Ports 22/80/443 offen (UFW)"
# Minimale Port-Öffnung reduziert die Angriffsfläche (Least Privilege).
# 22=SSH (Administration), 80/443=HTTP/HTTPS (Webdienste)
if command -v ufw >/dev/null 2>&1; then
  # Extrahiere Ports aus Zeilen mit ALLOW, z.B. "22/tcp", "80", "443/tcp"
  OPEN_PORTS=$(ufw status | awk '/ALLOW/ {print $1}' | sed 's#/tcp##g' | sed 's#/udp##g' | tr '\n' ' ')
  # Wenn irgendwas anderes als 22/80/443 drin ist -> fail
  if echo "$OPEN_PORTS" | tr ' ' '\n' | grep -vE '^(22|80|443)$' | grep -q '.'; then
    echo "[!] Unerwartete offene Ports gefunden: $OPEN_PORTS"
  else
    echo "[+] Nur erwartete Ports offen: $OPEN_PORTS"
    SCORE=$((SCORE+1))
  fi
else
  echo "[-] ufw nicht installiert, überspringe"
fi

echo
echo "[5] Fail2Ban aktiv"
# Fail2Ban erkennt und blockiert automatisch Brute-Force-Angriffe.
# Bannt IPs nach mehreren fehlgeschlagenen Loginversuchen temporär.
if command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client status >/dev/null 2>&1; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] Fail2Ban nicht aktiv oder nicht installiert"
fi

echo
echo "[6] Fail2Ban Nginx Jail (nginx-badbots)"
# Schützt vor automatisierten Scans und Bot-Angriffen auf den Webserver.
# Blockiert IPs mit verdächtigen Zugriffsmustern (404er, Bad Bots).
if command -v fail2ban-client >/dev/null 2>&1 && fail2ban-client status nginx-badbots >/dev/null 2>&1; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] nginx-badbots jail nicht aktiv (oder nginx/fail2ban nicht vorhanden)"
fi

echo
echo "[7] Nginx installiert"
# Nginx dient als Reverse Proxy mit TLS-Terminierung.
# Ermöglicht HTTPS-Verschlüsselung und zusätzliche Security-Header.
if command -v nginx >/dev/null 2>&1; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] Nginx nicht installiert"
fi

echo
echo "[8] TLS 1.2/1.3 konfiguriert (nginx)"
if command -v nginx >/dev/null 2>&1; then
  if nginx -T 2>/dev/null | grep -q "ssl_protocols TLSv1.2 TLSv1.3"; then
    echo "[+] OK"
    SCORE=$((SCORE+1))
  else
    echo "[-] TLS Konfiguration nicht gefunden"
  fi
else
  echo "[-] nginx nicht installiert, überspringe"
fi

echo
echo "[9] Nginx Rate Limiting aktiv"
if command -v nginx >/dev/null 2>&1; then
  if nginx -T 2>/dev/null | grep -E "limit_req|limit_conn" >/dev/null; then
    echo "[+] OK"
    SCORE=$((SCORE+1))
  else
    echo "[-] Keine Rate Limits gefunden"
  fi
else
  echo "[-] nginx nicht installiert, überspringe"
fi

echo
echo "[10] journald persistent"
if [ -f /etc/systemd/journald.conf ] && grep -q "Storage=persistent" /etc/systemd/journald.conf; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] journald nicht persistent"
fi

echo
echo "========================================"
echo "Hardening Score: $SCORE / $MAX_SCORE"
echo "========================================"

# Optionaler Netzwerk-Scan
if [ "$NETWORK_CHECK" = true ]; then
  echo
  echo "[Netzwerk-Scan] Offene Ports via nmap (localhost)"
  if command -v nmap >/dev/null 2>&1; then
    # Kurz & demo-tauglich: zeigt offene Ports + Service grob
    nmap -sS -Pn -p- --open localhost
  else
    echo "[-] nmap nicht installiert"
    echo "    Installieren: sudo apt install nmap"
  fi
fi

echo
if [ "$SCORE" -ge 8 ]; then
  echo "[✓] System gut gehärtet."
  exit 0
else
  echo "[!] Verbesserungspotenzial vorhanden."
  exit 1
fi