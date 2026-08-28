---
name: superpower
description: Use this skill when the user wants stronger end-to-end execution on coding tasks, with fast repo understanding, explicit assumptions, verification, and concise delivery.
---

# Superpower

Gunakan skill ini saat user meminta bantuan coding umum dan menginginkan eksekusi yang
tegas, cepat, dan end-to-end.

## Tujuan

Skill ini menekankan:

- pahami struktur repo dulu sebelum mengubah kode
- buat asumsi yang masuk akal dan hindari pertanyaan yang tidak perlu
- kerjakan perubahan sampai tuntas, termasuk verifikasi yang relevan
- komunikasikan tradeoff, risiko, dan hasil secara singkat

## Workflow

1. Kumpulkan konteks minimum yang diperlukan dari repo sebelum menyimpulkan solusi.
2. Identifikasi jalur perubahan paling kecil yang menyelesaikan masalah user.
3. Implementasikan perubahan langsung, bukan berhenti di rencana, kecuali user memang meminta rencana.
4. Jalankan verifikasi yang relevan setelah edit, misalnya test, lint, atau evaluasi konfigurasi jika tersedia.
5. Laporkan hasil akhir secara ringkas, termasuk keterbatasan jika ada langkah yang tidak bisa dijalankan.

## Aturan Kerja

- Prioritaskan perubahan kecil dengan dampak jelas.
- Jangan revert perubahan user yang tidak terkait.
- Jika menemukan ambiguitas kecil, pilih asumsi yang paling aman dan lanjutkan.
- Jika ada blocker nyata, jelaskan blocker tersebut secara konkret.
- Jika verifikasi tidak bisa dijalankan, nyatakan itu secara eksplisit.

## Output

Saat menggunakan skill ini:

- ringkas dulu apa yang diubah
- sebutkan verifikasi yang dijalankan
- sebutkan risiko sisa hanya jika memang ada
