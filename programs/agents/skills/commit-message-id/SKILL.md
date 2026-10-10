---
name: commit-message-id
description: Use this skill when writing, reviewing, or improving Git commit messages. It enforces the Indonesian Conventional Commit guideline from nyancodeid, including type, optional scope, subject, body, footer, revert, and breaking-change rules.
---

# Commit Message ID

Gunakan skill ini saat user meminta membuat commit, menulis commit message,
memperbaiki commit message, atau mereview commit message.

## Workflow

1. Baca perubahan yang akan di-commit dengan `git diff --cached` jika ada staged changes.
2. Jika belum ada staged changes dan user meminta commit langsung, cek `git diff` dan stage hanya perubahan yang relevan.
3. Tulis commit message memakai format di bawah.
4. Jaga setiap baris maksimal 100 karakter.
5. Jangan gunakan huruf kapital di awal subject.
6. Jangan akhiri subject dengan titik.
7. Gunakan imperative present tense.

## Format

Setiap commit message terdiri dari header, body, dan footer:

```text
<type>(<scope>): <subject>

<body>

<footer>
```

Header wajib. Scope opsional.

Commit sederhana boleh hanya memakai header:

```text
docs(changelog): update changelog to beta.5
```

Commit dengan body:

```text
fix(release): need to depend on latest rxjs and zone.js

The version in our package.json gets copied to the one we publish, and users need the latest of these.
```

## Type

Gunakan salah satu type berikut:

- `build`: perubahan sistem build atau dependency eksternal.
- `ci`: perubahan file konfigurasi dan script CI.
- `docs`: perubahan dokumentasi.
- `feat`: fitur baru.
- `fix`: perbaikan bug.
- `perf`: perubahan kode yang meningkatkan performa.
- `refactor`: perubahan kode yang tidak memperbaiki bug atau menambah fitur.
- `style`: perubahan formatting, whitespace, atau style tanpa mengubah makna kode.
- `test`: menambah test yang hilang atau memperbaiki test yang ada.

## Scope

Scope adalah area/paket yang terdampak. Gunakan scope yang paling spesifik dan mudah
dipahami pembaca changelog.

Untuk repo Angular, scope yang didukung:

- `animations`
- `common`
- `compiler`
- `compiler-cli`
- `core`
- `elements`
- `forms`
- `http`
- `language-service`
- `platform-browser`
- `platform-browser-dynamic`
- `platform-server`
- `platform-webworker`
- `platform-webworker-dynamic`
- `router`
- `service-worker`
- `upgrade`
- `zone.js`

Pengecualian scope:

- `packaging`: perubahan layout paket npm, path, package.json lintas paket, format d.ts, bundel.
- `changelog`: perubahan catatan rilis di `CHANGELOG.md`.
- `docs-infra`: perubahan docs-app Angular di direktori `/aio`.
- `ivy`: perubahan Ivy renderer.
- `ngcc`: perubahan Angular Compatibility Compiler.
- Tanpa scope: cocok untuk perubahan luas seperti `style`, `test`, `refactor`, atau docs umum.

Untuk repo non-Angular, pilih scope dari nama modul, folder, package, service,
atau area konfigurasi yang paling relevan, misalnya:

```text
feat(auth): add passkey login
fix(yazi): update folder icon color
docs: fix typo in setup guide
```

## Subject

Subject adalah deskripsi singkat perubahan:

- Gunakan imperative present tense: `change`, bukan `changed` atau `changes`.
- Jangan kapitalisasi huruf pertama.
- Jangan pakai titik di akhir.
- Buat spesifik dan ringkas.

## Body

Body memakai imperative present tense seperti subject.

Isi body harus menjelaskan:

- Motivasi perubahan.
- Perbandingan dengan perilaku sebelumnya.
- Dampak penting jika tidak jelas dari subject.

Body opsional untuk commit kecil yang sudah jelas dari header.

## Footer

Footer dipakai untuk:

- Referensi issue GitHub di akhir commit message.
- Breaking changes.

Breaking change harus dimulai dengan:

```text
BREAKING CHANGE:
```

Contoh:

```text
feat(api): require explicit tenant id

Reject requests without tenant id to prevent ambiguous routing.

BREAKING CHANGE: clients must send tenant_id in every request.
Closes #123
```

## Revert

Jika commit mengembalikan commit sebelumnya, header harus dimulai dengan `revert:`
diikuti header commit yang dikembalikan.

Body harus berisi:

```text
This reverts commit <hash>.
```

Contoh:

```text
revert: feat(auth): add passkey login

This reverts commit abc1234.
```
