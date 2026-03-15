#!/usr/bin/env bash
# =============================================================================
# Gemeinsame Helper-Funktionen für alle Hardening-Module
# =============================================================================
# Stellt einheitliche Logging-Funktionen, Root-Prüfung und 
# Paketverwaltungs-Wrapper bereit.
# =============================================================================
set -euo pipefail

# Vollständiger PATH sicherstellen - kritisch für systemnahe Tools
# (sshd, ufw, sysctl, nginx liegen oft in /usr/sbin)
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# =============================================================================
# Logging-Funktionen mit einheitlichem Format
# =============================================================================
log()  { echo -e "[*] $*"; }   # Informativ: Aktion wird ausgeführt
ok()   { echo -e "[+] $*"; }   # Erfolg: Aktion abgeschlossen
warn() { echo -e "[!] $*"; }   # Warnung: Potentielles Problem
err()  { echo -e "[-] $*" >&2; }  # Fehler: Kritisches Problem (stderr)

# =============================================================================
# Root-Prüfung - Hardening erfordert administrative Rechte
# =============================================================================
is_root() { [[ "${EUID:-$(id -u)}" -eq 0 ]]; }

ensure_root() {
  if ! is_root; then
    err "Bitte als root ausfuehren (sudo)."
    exit 1
  fi
}

# =============================================================================
# Paketverwaltung - nicht-interaktive Installation
# =============================================================================
apt_install() {
  # Installiert Pakete ohne Benutzerinteraktion
  # Usage: apt_install pkg1 pkg2 ...
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >/dev/null
  apt-get install -y --no-install-recommends "$@"
}

# =============================================================================
# Befehl/Paket-Abhängigkeiten prüfen und installieren
# =============================================================================
have_cmd() { command -v "$1" >/dev/null 2>&1; }

ensure_cmd_or_pkg() {
  # Prüft ob Befehl existiert, installiert sonst das zugehörige Paket
  # Usage: ensure_cmd_or_pkg <cmd> <pkg>
  local cmd="$1" pkg="$2"
  if ! have_cmd "$cmd"; then
    warn "Command '$cmd' fehlt -> installiere Paket '$pkg'"
    apt_install "$pkg"
  fi
}

# =============================================================================
# Systemd-Service-Verwaltung  
# =============================================================================
ensure_service_exists() {
  # Prüft ob ein Systemd-Service existiert
  # Usage: ensure_service_exists ssh.service
  local svc="$1"
  systemctl list-unit-files | awk '{print $1}' | grep -qx "$svc"
}

safe_restart() {
  # Startet Service neu (kompatibel mit init.d und systemd)
  # Fehler werden toleriert für Robustheit
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    systemctl restart "$svc" || true
  else
    service "$svc" restart || true
  fi
}