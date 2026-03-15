#!/usr/bin/env bash
# =============================================================================
# Debian Hardening Script - Hauptskript
# =============================================================================
# Dieses Skript orchestriert die Systemhärtung gemäß CIS Benchmarks und
# Best Practices. Es führt modulare Hardening-Schritte sequenziell aus.
#
# Sicherheitsziel: Minimierung der Angriffsfläche durch Defense-in-Depth
# =============================================================================
set -euo pipefail

# Lädt gemeinsame Helper-Funktionen für einheitliche Fehlerbehandlung
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/modules/00_common.sh"

ensure_root

ok "Starte Debian 13.3 Hardening..."

# Basis-Abhängigkeiten für sichere Paketverwaltung installieren
# - ca-certificates: Vertrauenswürdige Root-Zertifikate für HTTPS-Verbindungen
# - apt-transport-https: Ermöglicht verschlüsselte Paketquellen
# - gnupg: Signaturprüfung von Paketen (Integritätssicherung)
log "Installiere Basis-Tools (falls noetig)"
apt_install ca-certificates apt-transport-https gnupg

# Sicherstellen, dass kritische Systemtools verfügbar sind
ensure_cmd_or_pkg dpkg-reconfigure debconf    # Konfigurationsmanagement
ensure_cmd_or_pkg sysctl procps               # Kernel-Parameter-Steuerung
ensure_cmd_or_pkg sshd openssh-server         # Sicherer Remote-Zugang
ensure_cmd_or_pkg ufw ufw                     # Paketfilter-Firewall

# Modulare Ausführung der Hardening-Schritte
run_module() {
  local m="$1"
  if [[ -f "$SCRIPT_DIR/$m" ]]; then
    ok "Führe $m aus"
    bash "$SCRIPT_DIR/$m"
  else
    warn "Modul fehlt: $m (skip)"
  fi
}

run_module "modules/01_update_system.sh"
run_module "modules/02_users_ssh.sh"
run_module "modules/03_firewall.sh"
run_module "modules/04_fail2ban.sh"
run_module "modules/05_sysctl.sh"
run_module "modules/06_nginx_tls.sh"
run_module "modules/07_disable_services.sh"
run_module "modules/09_sudo_hardening.sh"
run_module "modules/11_logging.sh"
run_module "modules/13_nginx_rate_limit.sh"
run_module "modules/14_fail2ban_nginx.sh"
run_module "modules/99_verify.sh"

ok "Hardening abgeschlossen. Reboot empfohlen."
read -r -p "Möchten Sie jetzt neu starten? (j/n) " ans || true
if [[ "${ans:-n}" =~ ^[jJyY]$ ]]; then
  reboot
else
  ok "Neustart übersprungen. Bitte starten Sie das System später neu."
fi