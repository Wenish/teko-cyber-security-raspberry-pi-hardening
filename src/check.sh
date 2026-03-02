#!/bin/bash

echo "========================================"
echo "   Raspberry Pi Hardening Check"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
  echo "[!] Bitte als root ausfuehren (sudo ./check.sh)"
  exit 1
fi

SCORE=0
MAX_SCORE=10

echo
echo "[1] SSH Passwort-Login deaktiviert"
if sshd -T | grep -q "passwordauthentication no"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] NICHT deaktiviert"
fi

echo
echo "[2] Root-Login deaktiviert"
if sshd -T | grep -q "permitrootlogin no"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] Root-Login erlaubt"
fi

echo
echo "[3] UFW aktiv"
if ufw status | grep -q "Status: active"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] UFW nicht aktiv"
fi

echo
echo "[4] Nur Ports 22/80/443 offen"
OPEN_PORTS=$(ufw status | grep ALLOW | awk '{print $1}')
if echo "$OPEN_PORTS" | grep -vqE "^(22|80|443)"; then
  echo "[!] Unerwartete offene Ports gefunden"
else
  echo "[+] Nur erwartete Ports offen"
  SCORE=$((SCORE+1))
fi

echo
echo "[5] Fail2Ban aktiv"
if fail2ban-client status >/dev/null 2>&1; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[!] Fail2Ban nicht aktiv"
fi

echo
echo "[6] Nginx installiert"
if command -v nginx >/dev/null 2>&1; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] Nginx nicht installiert"
fi

echo
echo "[7] TLS 1.2/1.3 konfiguriert"
if nginx -T 2>/dev/null | grep -q "ssl_protocols TLSv1.2 TLSv1.3"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] TLS Konfiguration nicht gefunden"
fi

echo
echo "[8] Nginx Rate Limiting aktiv"
if nginx -T 2>/dev/null | grep -E "limit_req|limit_conn" >/dev/null; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] Keine Rate Limits gefunden"
fi

echo
echo "[9] journald persistent"
if grep -q "Storage=persistent" /etc/systemd/journald.conf; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] journald nicht persistent"
fi

echo
echo "[10] sysctl Hardening aktiv"
if sysctl net.ipv4.tcp_syncookies 2>/dev/null | grep -q "= 1"; then
  echo "[+] OK"
  SCORE=$((SCORE+1))
else
  echo "[-] tcp_syncookies nicht gesetzt"
fi

echo
echo "========================================"
echo "Hardening Score: $SCORE / $MAX_SCORE"
echo "========================================"

if [ "$SCORE" -ge 8 ]; then
  echo "[✓] System gut gehaertet."
  exit 0
else
  echo "[!] Verbesserungspotenzial vorhanden."
  exit 1
fi