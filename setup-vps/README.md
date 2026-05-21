# Setup VPS Arch Linux

Panduan singkat setup awal VPS Arch Linux menggunakan script:

- `first-run.sh`
- `second-run.sh`
- `secrets-setup.json`

Script diambil langsung dari repository:

```text
https://github.com/Wanmixc/home-manager-linux
```

---

## 1. Login ke VPS

Login pertama kali ke VPS sebagai `root`:

```bash
ssh root@IP_VPS
```

Contoh:

```bash
ssh root@103.190.0.119
```

---

## 2. Masuk ke `/tmp`

Setelah berhasil login, masuk ke folder `/tmp`:

```bash
cd /tmp
```

Download file setup:

```bash
curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/first-run.sh
curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/second-run.sh
curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/secrets-setup.example.json
```

Rename file example menjadi config asli:

```bash
mv secrets-setup.example.json secrets-setup.json
```

Edit file config:

```bash
nano secrets-setup.json
```

Isi sesuai kebutuhan setup kamu.

Contoh:

```json
{
  "new_user": {
    "username": "wanmixc",
    "password": "PasswordKamuYangKuat"
  },
  "ntfy": {
    "url": "https://ntfy.sh/topic-kamu"
  }
}
```

Pastikan nilai berikut sudah diganti:

```text
__CHANGE_ME_USERNAME__
__CHANGE_ME_PASSWORD__
__CHANGE_ME_NTFY_URL__
```

---

## 3. Jalankan `first-run.sh`

Beri permission execute:

```bash
chmod +x first-run.sh
```

Jalankan script pertama sebagai `root`:

```bash
./first-run.sh
```

Script ini akan:

- Membuat user baru
- Set password user baru
- Menambahkan user ke grup `wheel`
- Mengaktifkan akses sudo
- Install basic tools
- Membuat folder setup di home user baru:

```text
/home/<username>/Extra/setup_vps
```

- Menyalin file setup ke folder tersebut

---

## 4. Tes login SSH dengan user baru

Setelah `first-run.sh` selesai, buka terminal baru dari komputer lokal.

Tes login ke VPS menggunakan user baru:

```bash
ssh <username>@IP_VPS
```

Contoh:

```bash
ssh wanmixc@103.190.0.119
```

Jika VPS menggunakan NAT/port forwarding dari provider, gunakan port yang diberikan provider:

```bash
ssh -p PORT_PROVIDER <username>@IP_VPS
```

Contoh:

```bash
ssh -p 9898 wanmixc@103.190.0.119
```

Jika login berhasil, lanjut ke tahap berikutnya.

---

## 5. Masuk ke folder setup VPS

Setelah login sebagai user baru:

```bash
cd ~/Extra/setup_vps
```

Atau path lengkap:

```bash
cd /home/<username>/Extra/setup_vps
```

Contoh:

```bash
cd /home/wanmixc/Extra/setup_vps
```

---

## 6. Jalankan `second-run.sh`

Beri permission execute:

```bash
sudo chmod +x second-run.sh
```

Jalankan script kedua:

```bash
./second-run.sh
```

## 6. Selesai

Setelah script selesai, logout lalu login ulang agar grup baru seperti `docker` dan `nix-users` aktif.

```bash
exit
```

Login ulang:

```bash
ssh <username>@IP_VPS
```

Cek sudo:

```bash
sudo whoami
```

Output yang benar:

```text
root
```

Cek Docker:

```bash
docker ps
```

Cek Nix:

```bash
nix --version
```

Cek Home Manager:

```bash
home-manager --version
```

---

## Catatan Penting

Jangan upload atau commit file ini ke repository publik:

```text
secrets-setup.json
```

Karena berisi:

- Username
- Password
- Link ntfy pribadi

Yang boleh masuk repository publik hanya:

```text
secrets-setup.example.json
```

---

## Ringkasan Command

```bash
ssh root@IP_VPS

cd /tmp

curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/first-run.sh
curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/second-run.sh
curl -LO https://raw.githubusercontent.com/Wanmixc/home-manager-linux/refs/heads/main/setup-vps/secrets-setup.example.json

mv secrets-setup.example.json secrets-setup.json
nano secrets-setup.json

chmod +x first-run.sh
./first-run.sh
```

Setelah itu test login user baru dari terminal lokal:

```bash
ssh <username>@IP_VPS
```

Lalu di user baru:

```bash
cd ~/Extra/setup_vps
sudo chmod +x second-run.sh
./second-run.sh
```

Delete Folder /setup_vps

```bash
cd ..
rm -rf setup_vps
```
Done.
