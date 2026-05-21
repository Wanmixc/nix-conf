#!/usr/bin/env bash
set -Eeuo pipefail

echo "=== Second Run VPS Setup - Arch Linux ==="

if [ "$EUID" -eq 0 ]; then
  echo "Jangan jalankan script ini sebagai root."
  echo "Login sebagai user baru, lalu jalankan: ./second-run.sh"
  exit 1
fi

if [ ! -f /etc/arch-release ]; then
  echo "Script ini dibuat untuk Arch Linux."
  exit 1
fi

CURRENT_USER="$(id -un)"
USER_HOME="$HOME"
DATE_NOW="$(date +%F-%H%M%S)"
LOG_DIR="$USER_HOME/Extra/setup_vps/logs"
CONFIG_FILE="${CONFIG_FILE:-./secrets-setup.json}"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/second-run-$DATE_NOW.log") 2>&1

CURRENT_STEP="init"
HM_SWITCH_STATUS="not_run"
CASAOS_STATUS="not_run"

HM_REPO="https://github.com/Wanmixc/home-manager-linux.git"
HM_BRANCH="vps"
HM_RELEASE="25.11"
PATCH_HOME_NIX="true"
INSTALL_CASAOS="true"
GITHUB_TOKEN=""

fail_config() {
  echo
  echo "ERROR: Konfigurasi belum lengkap."
  echo "Silakan update file:"
  echo "$CONFIG_FILE"
  echo
  echo "Field bermasalah: $1"
  exit 1
}

ensure_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm jq
  fi
}

load_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    fail_config "$CONFIG_FILE tidak ditemukan"
  fi

  ensure_jq

  NEW_USER="$(jq -r '.new_user.username // empty' "$CONFIG_FILE")"
  NTFY_URL="$(jq -r '.ntfy.url // empty' "$CONFIG_FILE")"

  [ -z "$NEW_USER" ] || [[ "$NEW_USER" == __CHANGE_ME* ]] && fail_config "new_user.username"
  [ -z "$NTFY_URL" ] || [[ "$NTFY_URL" == __CHANGE_ME* ]] && fail_config "ntfy.url"

  if [ "$NEW_USER" != "$CURRENT_USER" ]; then
    fail_config "new_user.username tidak sama dengan user aktif. Config: $NEW_USER, aktif: $CURRENT_USER"
  fi
}

notify_ntfy() {
  local title="$1"
  local message="$2"
  local priority="${3:-default}"
  local tags="${4:-information_source}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsS -m 10 \
      -H "Title: $title" \
      -H "Priority: $priority" \
      -H "Tags: $tags" \
      -d "$message" \
      "$NTFY_URL" >/dev/null 2>&1 || true
  fi
}

on_error() {
  local exit_code="$?"
  local line_no="${BASH_LINENO[0]:-unknown}"

  notify_ntfy \
    "VPS Setup FAILED" \
    "Host: $(hostname)
User: ${CURRENT_USER:-unknown}
Step: ${CURRENT_STEP:-unknown}
Line: $line_no
Exit code: $exit_code
Log: ${LOG_DIR:-unknown}" \
    "high" \
    "x,warning"

  exit "$exit_code"
}

load_config
trap on_error ERR

echo "User aktif : $CURRENT_USER"
echo "Home       : $USER_HOME"
echo "Log        : $LOG_DIR/second-run-$DATE_NOW.log"
echo

notify_ntfy \
  "VPS Setup STARTED" \
  "Setup VPS dimulai di host $(hostname).
User: $CURRENT_USER
Log: $LOG_DIR/second-run-$DATE_NOW.log" \
  "default" \
  "rocket"

CURRENT_STEP="Cek akses sudo"
echo "Cek akses sudo..."
sudo -v

echo
CURRENT_STEP="Install package dasar"
echo "=== 1. Install package dasar ==="

sudo pacman -Syu --needed --noconfirm \
  sudo \
  openssh \
  git \
  curl \
  wget \
  base-devel \
  nano \
  vim \
  htop \
  btop \
  unzip \
  zip \
  ca-certificates \
  xz \
  jq \
  ufw \
  fail2ban \
  pacman-contrib \
  ncdu \
  iotop \
  lsof \
  bind-tools \
  traceroute \
  rsync \
  restic \
  rclone \
  smartmontools \
  hdparm \
  parted \
  gptfdisk \
  e2fsprogs \
  xfsprogs \
  btrfs-progs \
  nfs-utils \
  cifs-utils \
  etckeeper

echo
CURRENT_STEP="Disable root login SSH"
echo "=== 2. Disable root login SSH ==="

SSHD_CONFIG="/etc/ssh/sshd_config"
SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
SSHD_DROPIN="$SSHD_DROPIN_DIR/99-vps-hardening.conf"

sudo mkdir -p "$SSHD_DROPIN_DIR"

if [ -f "$SSHD_CONFIG" ]; then
  sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.backup.$DATE_NOW"

  sudo sed -i -E 's/^([[:space:]]*)PermitRootLogin[[:space:]]+.*/# \0/' "$SSHD_CONFIG"
  sudo sed -i -E 's/^([[:space:]]*)PasswordAuthentication[[:space:]]+.*/# \0/' "$SSHD_CONFIG"
  sudo sed -i -E 's/^([[:space:]]*)KbdInteractiveAuthentication[[:space:]]+.*/# \0/' "$SSHD_CONFIG"
  sudo sed -i -E 's/^([[:space:]]*)UsePAM[[:space:]]+.*/# \0/' "$SSHD_CONFIG"
  sudo sed -i -E 's/^([[:space:]]*)PubkeyAuthentication[[:space:]]+.*/# \0/' "$SSHD_CONFIG"

  if ! sudo grep -Eq '^[[:space:]]*Include[[:space:]]+/etc/ssh/sshd_config\.d/\*\.conf' "$SSHD_CONFIG"; then
    sudo sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' "$SSHD_CONFIG"
  fi
fi

sudo tee "$SSHD_DROPIN" >/dev/null <<'EOF'
# Managed by second-run.sh
PermitRootLogin no
PasswordAuthentication yes
KbdInteractiveAuthentication yes
UsePAM yes
PubkeyAuthentication yes
EOF

sudo chmod 644 "$SSHD_DROPIN"

echo "Validasi konfigurasi SSH..."
sudo sshd -t

echo "Enable dan restart sshd..."
sudo systemctl enable --now sshd
sudo systemctl restart sshd

echo "SSH listen:"
sudo ss -ltnp | grep sshd || true

notify_ntfy \
  "SSH Hardening SUCCESS" \
  "Root SSH login berhasil dinonaktifkan di host $(hostname). Port SSH tidak diubah." \
  "default" \
  "lock,white_check_mark"

echo
CURRENT_STEP="Setup firewall UFW dan fail2ban"
echo "=== 3. Setup firewall UFW + fail2ban ==="

sudo ufw allow OpenSSH
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable
sudo ufw status verbose

sudo systemctl enable --now fail2ban
sudo systemctl enable --now paccache.timer || true

echo
CURRENT_STEP="Install Nix"
echo "=== 4. Install Nix via pacman ==="

sudo pacman -S --needed --noconfirm nix

sudo mkdir -p /etc/nix
sudo touch /etc/nix/nix.conf
sudo cp /etc/nix/nix.conf "/etc/nix/nix.conf.backup.$DATE_NOW"

if sudo grep -q '^experimental-features' /etc/nix/nix.conf; then
  sudo sed -i 's/^experimental-features.*/experimental-features = nix-command flakes/' /etc/nix/nix.conf
else
  echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
fi

if sudo grep -q '^trusted-users' /etc/nix/nix.conf; then
  sudo sed -i "s/^trusted-users.*/trusted-users = root $CURRENT_USER/" /etc/nix/nix.conf
else
  echo "trusted-users = root $CURRENT_USER" | sudo tee -a /etc/nix/nix.conf >/dev/null
fi

if getent group nix-users >/dev/null 2>&1; then
  echo "Menambahkan user ke grup nix-users..."
  sudo usermod -aG nix-users "$CURRENT_USER"
fi

sudo systemctl enable --now nix-daemon.service
sudo systemctl restart nix-daemon.service

notify_ntfy \
  "Nix SUCCESS" \
  "Nix berhasil diinstall dan flakes sudah diaktifkan di host $(hostname)." \
  "default" \
  "package,white_check_mark"

echo
CURRENT_STEP="Install Home Manager"
echo "=== 5. Install Home Manager release-$HM_RELEASE ==="

HM_INSTALL_SCRIPT="/tmp/install-home-manager-$CURRENT_USER.sh"

cat > "$HM_INSTALL_SCRIPT" <<HMEOF
#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f /etc/profile.d/nix-daemon.sh ]; then
  source /etc/profile.d/nix-daemon.sh
elif [ -f /etc/profile.d/nix.sh ]; then
  source /etc/profile.d/nix.sh
fi

export NIX_CONFIG="experimental-features = nix-command flakes"

echo "Nix version:"
nix --version

nix-channel --remove nixpkgs >/dev/null 2>&1 || true
nix-channel --remove home-manager >/dev/null 2>&1 || true

nix-channel --add "https://nixos.org/channels/nixos-${HM_RELEASE}" nixpkgs
nix-channel --add "https://github.com/nix-community/home-manager/archive/release-${HM_RELEASE}.tar.gz" home-manager
nix-channel --update

nix-shell '<home-manager>' -A install
HMEOF

chmod +x "$HM_INSTALL_SCRIPT"
sudo -iu "$CURRENT_USER" bash "$HM_INSTALL_SCRIPT"

notify_ntfy \
  "Home Manager Install SUCCESS" \
  "Home Manager release-$HM_RELEASE berhasil diinstall di host $(hostname)." \
  "default" \
  "house,white_check_mark"

echo
CURRENT_STEP="Clone config Home Manager"
echo "=== 6. Clone config Home Manager ==="

HM_DIR="$USER_HOME/.config/home-manager"

if [ -d "$HM_DIR" ]; then
  BACKUP_DIR="$USER_HOME/.config/home-manager.backup.$DATE_NOW"
  echo "Backup config lama ke: $BACKUP_DIR"
  mv "$HM_DIR" "$BACKUP_DIR"
fi

git clone --branch "$HM_BRANCH" --depth 1 "$HM_REPO" "$HM_DIR"

cd "$HM_DIR"

echo "Membuat secrets.json untuk Home Manager..."
jq -n --arg token "$GITHUB_TOKEN" '{github_token: $token}' > "$HM_DIR/secrets.json"
chmod 600 "$HM_DIR/secrets.json"

if [[ "$PATCH_HOME_NIX" == "true" ]]; then
  echo "Patch home.nix untuk user dan home directory saat ini..."

  if [ -f "$HM_DIR/home.nix" ]; then
    sed -i -E "s/home\.username = \"[^\"]+\";/home.username = \"$CURRENT_USER\";/" "$HM_DIR/home.nix"
    sed -i -E "s#home\.homeDirectory = \"[^\"]+\";#home.homeDirectory = \"$USER_HOME\";#" "$HM_DIR/home.nix"
    sed -i "s#/home/wanmixc#$USER_HOME#g" "$HM_DIR/home.nix"
  else
    echo "PERINGATAN: $HM_DIR/home.nix tidak ditemukan."
  fi
fi

echo
CURRENT_STEP="home-manager switch"
echo "=== 7. home-manager switch ==="

HM_SWITCH_SCRIPT="/tmp/home-manager-switch-$CURRENT_USER.sh"

cat > "$HM_SWITCH_SCRIPT" <<'SWITCHEOF'
#!/usr/bin/env bash
set -Eeuo pipefail

if [ -f /etc/profile.d/nix-daemon.sh ]; then
  source /etc/profile.d/nix-daemon.sh
elif [ -f /etc/profile.d/nix.sh ]; then
  source /etc/profile.d/nix.sh
fi

if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

export PATH="$HOME/.nix-profile/bin:$PATH"
export NIX_CONFIG="experimental-features = nix-command flakes"

cd "$HOME/.config/home-manager"

if command -v home-manager >/dev/null 2>&1; then
  home-manager switch
else
  "$HOME/.nix-profile/bin/home-manager" switch
fi
SWITCHEOF

chmod +x "$HM_SWITCH_SCRIPT"

set +e
sudo -iu "$CURRENT_USER" bash "$HM_SWITCH_SCRIPT"
HM_STATUS=$?
set -e

if [ "$HM_STATUS" -ne 0 ]; then
  HM_SWITCH_STATUS="failed"

  notify_ntfy \
    "Home Manager Switch FAILED" \
    "home-manager switch gagal di host $(hostname).
User: $CURRENT_USER
Cek log: $LOG_DIR/second-run-$DATE_NOW.log" \
    "high" \
    "x,house"

  echo
  echo "PERINGATAN: home-manager switch gagal."
  echo "Kemungkinan dari config repo, bukan dari installer."
  echo "Cek log di:"
  echo "$LOG_DIR/second-run-$DATE_NOW.log"
  echo
  echo "Script tetap lanjut ke AUR dan CasaOS."
else
  HM_SWITCH_STATUS="success"

  notify_ntfy \
    "Home Manager Switch SUCCESS" \
    "home-manager switch berhasil di host $(hostname)." \
    "default" \
    "white_check_mark,house"

  echo "home-manager switch berhasil."
fi

echo
CURRENT_STEP="Install udevil dan mergerfs dari AUR tanpa yay"
echo "=== 8. Install udevil & mergerfs dari AUR tanpa yay ==="

AUR_BUILD_DIR="$USER_HOME/Extra/setup_vps/aur-build"
mkdir -p "$AUR_BUILD_DIR"

install_aur_package() {
  local package_name="$1"
  local aur_url="https://aur.archlinux.org/${package_name}.git"
  local package_dir="$AUR_BUILD_DIR/$package_name"

  echo
  echo "Installing AUR package: $package_name"

  rm -rf "$package_dir"
  git clone "$aur_url" "$package_dir"

  cd "$package_dir"

  makepkg -si --needed --noconfirm
}

install_aur_package "udevil"
install_aur_package "mergerfs"

notify_ntfy \
  "AUR Packages SUCCESS" \
  "udevil dan mergerfs berhasil diinstall manual dari AUR di host $(hostname)." \
  "default" \
  "package,white_check_mark"

echo
CURRENT_STEP="Install dependency CasaOS"
echo "=== 9. Install dependency CasaOS untuk Arch ==="

sudo pacman -S --needed --noconfirm \
  wget \
  curl \
  smartmontools \
  ntfs-3g \
  net-tools \
  samba \
  apparmor \
  docker \
  parted \
  cifs-utils \
  unzip \
  docker-compose \
  rclone

echo "Mengaktifkan Docker..."
sudo systemctl enable --now docker

echo "Menambahkan user '$CURRENT_USER' ke grup docker..."
if sudo usermod -aG docker "$CURRENT_USER"; then
  notify_ntfy \
    "Docker Group SUCCESS" \
    "User '$CURRENT_USER' berhasil ditambahkan ke grup docker di host $(hostname)." \
    "default" \
    "white_check_mark,docker"
else
  notify_ntfy \
    "Docker Group FAILED" \
    "Gagal menambahkan user '$CURRENT_USER' ke grup docker di host $(hostname)." \
    "high" \
    "x,docker"
  exit 1
fi

sudo systemctl enable --now apparmor || true

if [[ "$INSTALL_CASAOS" == "true" ]]; then
  echo
  CURRENT_STEP="Install CasaOS"
  echo "=== 10. Install CasaOS ==="

  CASAOS_SCRIPT="/tmp/casaos-install-$DATE_NOW.sh"

  curl -fsSL https://get.casaos.io -o "$CASAOS_SCRIPT"
  chmod +x "$CASAOS_SCRIPT"

  sed -i -E 's/^([[:space:]]*)(Update_Package_Resource)$/\1# \2/' "$CASAOS_SCRIPT" || true
  sed -i -E 's/^([[:space:]]*)(Install_Depends)$/\1# \2/' "$CASAOS_SCRIPT" || true

  set +e
  sudo bash "$CASAOS_SCRIPT"
  CASAOS_EXIT=$?
  set -e

  if [ "$CASAOS_EXIT" -ne 0 ]; then
    CASAOS_STATUS="failed"

    notify_ntfy \
      "CasaOS Install FAILED" \
      "Install CasaOS gagal di host $(hostname).
Cek log: $LOG_DIR/second-run-$DATE_NOW.log" \
      "high" \
      "x,house"

    echo
    echo "PERINGATAN: CasaOS gagal diinstall."
    echo "Cek log di:"
    echo "$LOG_DIR/second-run-$DATE_NOW.log"
  else
    CASAOS_STATUS="success"

    notify_ntfy \
      "CasaOS Install SUCCESS" \
      "CasaOS berhasil diinstall di host $(hostname)." \
      "default" \
      "white_check_mark,house"
  fi
fi

echo
CURRENT_STEP="Backup config penting"
echo "=== 11. Backup config penting ==="

BACKUP_CONFIG_DIR="$USER_HOME/Extra/backup-config/$DATE_NOW"
mkdir -p "$BACKUP_CONFIG_DIR"

sudo cp -r /etc/ssh "$BACKUP_CONFIG_DIR/ssh" 2>/dev/null || true
sudo cp -r /etc/nix "$BACKUP_CONFIG_DIR/nix" 2>/dev/null || true
cp -r "$HM_DIR" "$BACKUP_CONFIG_DIR/home-manager" 2>/dev/null || true

sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$USER_HOME/Extra/backup-config" || true

if [ ! -d /etc/.git ]; then
  sudo etckeeper init || true
fi

sudo etckeeper commit "VPS setup $DATE_NOW" || true

CURRENT_STEP="Selesai"

notify_ntfy \
  "VPS Setup FINISHED" \
  "Setup VPS selesai di host $(hostname).
User: $CURRENT_USER
SSH port: tidak diubah
Home Manager switch: $HM_SWITCH_STATUS
CasaOS: $CASAOS_STATUS
Log: $LOG_DIR/second-run-$DATE_NOW.log" \
  "default" \
  "white_check_mark,tada"

echo
echo "=== Selesai ==="
echo "SSH root login       : disabled"
echo "SSH port             : tidak diubah"
echo "Home Manager         : $HM_DIR"
echo "Home Manager switch  : $HM_SWITCH_STATUS"
echo "CasaOS               : $CASAOS_STATUS"
echo "Log                  : $LOG_DIR/second-run-$DATE_NOW.log"
echo
echo "PENTING:"
echo "1. Logout-login ulang agar grup docker/nix-users aktif."
echo "2. Cek SSH:"
echo "   ssh $CURRENT_USER@127.0.0.1"
echo "3. Cek Docker setelah login ulang:"
echo "   docker ps"
