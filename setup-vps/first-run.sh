#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== First Run VPS Setup - Arch Linux ==="

if [ "$EUID" -ne 0 ]; then
  echo "Script ini harus dijalankan sebagai root."
  exit 1
fi

if [ ! -f /etc/arch-release ]; then
  echo "Script ini dibuat untuk Arch Linux."
  exit 1
fi

CONFIG_FILE="${CONFIG_FILE:-./secrets-setup.json}"

fail_config() {
  echo
  echo "ERROR: Konfigurasi belum lengkap."
  echo "Silakan copy dan edit file:"
  echo "cp secrets-setup.example.json secrets-setup.json"
  echo "nano secrets-setup.json"
  echo
  echo "Field bermasalah: $1"
  exit 1
}

ensure_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "Install jq..."
    pacman -Syu --needed --noconfirm jq
  fi
}

load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    fail_config "$CONFIG_FILE tidak ditemukan"
  fi

  ensure_jq

  NEW_USER="$(jq -r '.new_user.username // empty' "$CONFIG_FILE")"
  NEW_PASSWORD="$(jq -r '.new_user.password // empty' "$CONFIG_FILE")"

  [ -z "$NEW_USER" ] || [[ "$NEW_USER" == __CHANGE_ME* ]] && fail_config "new_user.username"
  [ -z "$NEW_PASSWORD" ] || [[ "$NEW_PASSWORD" == __CHANGE_ME* ]] && fail_config "new_user.password"
}

load_config

USER_HOME="/home/$NEW_USER"

echo "Install sudo dan basic tools..."
pacman -Syu --needed --noconfirm \
  sudo \
  curl \
  wget \
  git \
  nano \
  vim \
  htop \
  unzip \
  zip \
  ca-certificates \
  gnupg \
  base-devel \
  openssh \
  jq

if id "$NEW_USER" &>/dev/null; then
  echo "User '$NEW_USER' sudah ada."
else
  echo "Membuat user baru: $NEW_USER"
  useradd -m -G wheel -s /bin/bash "$NEW_USER"
fi

echo "Set password untuk user '$NEW_USER'..."
echo "$NEW_USER:$NEW_PASSWORD" | chpasswd
unset NEW_PASSWORD

echo "Mengaktifkan akses sudo untuk grup wheel..."
cat > /etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF

chmod 440 /etc/sudoers.d/10-wheel

if visudo -cf /etc/sudoers.d/10-wheel; then
  echo "Konfigurasi sudo valid."
else
  echo "Konfigurasi sudo tidak valid."
  rm -f /etc/sudoers.d/10-wheel
  exit 1
fi

echo "Membuat folder setup di home user baru..."
mkdir -p "$USER_HOME/Extra/setup_vps"

SCRIPT_PATH="$(readlink -f "$0")"

if [ -f "$SCRIPT_PATH" ]; then
  cp "$SCRIPT_PATH" "$USER_HOME/Extra/setup_vps/first-run.sh"
  chmod +x "$USER_HOME/Extra/setup_vps/first-run.sh"
fi

if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "$USER_HOME/Extra/setup_vps/secrets-setup.json"
  chmod 600 "$USER_HOME/Extra/setup_vps/secrets-setup.json"
fi

if [ -f "./second-run.sh" ]; then
  cp "./second-run.sh" "$USER_HOME/Extra/setup_vps/second-run.sh"
  chmod +x "$USER_HOME/Extra/setup_vps/second-run.sh"
fi

chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/Extra"

echo
echo "Selesai."
echo "User baru : $NEW_USER"
echo "Home      : $USER_HOME"
echo "Grup sudo : wheel"
echo
echo "Login sebagai user baru:"
echo "su - $NEW_USER"
echo
echo "Lalu jalankan:"
echo "cd ~/Extra/setup_vps"
echo "./second-run.sh"
