#!/bin/bash

echo "[*] Fail2Ban installieren"

apt install -y fail2ban

cat <<EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 3

[sshd]
enabled = true
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo "[✓] Fail2Ban Installation abgeschlossen"