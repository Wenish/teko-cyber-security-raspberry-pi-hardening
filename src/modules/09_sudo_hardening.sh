#!/bin/bash

echo "[*] Sudo Hardening"

SUDOERS_D="/etc/sudoers.d/99-hardening"

cat <<EOF > "$SUDOERS_D"
Defaults use_pty
Defaults logfile="/var/log/sudo.log"
Defaults loglinelen=0
EOF

chmod 440 "$SUDOERS_D"

echo "[+] Sudo Hardening aktiviert (use_pty + sudo.log)"