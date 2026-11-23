# Catatan Backend untuk App Android

API: `https://api.ourprojects.my.id/v1`. Terakhir dicek 23 Nov 2026 pada backend commit `feca39d` (sudah ter-deploy), memakai akun tes `bioverse.qa+…@example.com`.

## Masih terbuka

1. **`completed_today` dan `my_last_submission_status` di `GET /app/missions` selalu `false`/`null`.**
   - Penyebab: di `ListActiveMissionsForUserRow`, `MyLastSubmissionStatus` bertipe `string`. Untuk misi yang belum pernah di-submit, subquery-nya `NULL`, sehingga `rows.Scan` gagal. Akibatnya seluruh query error, lalu handler diam-diam fallback ke `rawMissions` tanpa kedua field itu.
   - Perbaikan: `COALESCE((SELECT s.status::text ...), '')` di query, atau override sqlc ke `pgtype.Text`. Error di handler juga sebaiknya di-log, jangan ditelan.
   - Catatan tambahan: `completed_today` memakai `CURRENT_DATE` (tanggal server, UTC), sedangkan `submission_date` memakai tanggal lokal user. Antara 00:00–07:00 WIB hasilnya bisa salah.
   - *Sementara:* app mengisi kedua field ini sendiri dari `GET /app/mission-submissions/my`.

2. **`units/my` mengarang laporan foto.** Kalau sebuah unit belum punya milestone asli, handler membuat 3 milestone palsu: foto stok Unsplash, `is_verified_healthy: true`, caption "Bulan 1/3/6", dan `captured_at` di masa depan. Untuk fitur transparansi, ini menyesatkan.
   - Perbaikan: kirim `milestones: []` saja (atau milestone dengan `is_placeholder: true`).
   - *Sementara:* app menganggap laporan dengan tanggal di masa depan sebagai "Upcoming", bukan "received".

3. **Fallback CV meloloskan foto apa pun.** Karena service CV di production mati, `StubCVVerifier` memverifikasi semua foto (confidence 0.92). Di tes, sebuah PNG polos berwarna hijau lolos dan mendapat poin. Untuk demo tidak apa-apa, tapi user bisa farming poin.
   - Saran: nyalakan service CV, atau batasi fallback ke environment non-production. Pakai `needs_review` dan sediakan halaman review di admin.

4. **Pesan receipt submit misi tidak cocok.** Status sudah `verified`, tapi `message` masih "Computer vision verification in progress."

## Sudah beres (diverifikasi di API live)
- `POST /missions/{id}/submit` tidak lagi 500; balasannya `202` dan poin/XP langsung masuk.
- `GET /users/me/stats` 200, dan `missions_completed` naik setelah misi terverifikasi.
- Merawat pet menaikkan streak; `xp_to_next_level` tersedia; `GET /pets/species` mencakup satwa laut, mangrove, dan hutan.
- Proyek memiliki `location_name`, koordinat, dan `contributors_count`. Lokasi mangrove Tanjung Lesung sudah benar (Banten).
- Seed: 3 proyek (coral, mangrove, tree), 3 berita, dan 4 misi resmi dengan foto + durasi (duplikat sudah dihapus).
- Endpoint `GET /mission-submissions/my`, `GET /conservation/units/my`, dan notifikasi dengan cursor sudah tersedia.
- Tipe donasi `mangrove_planting`, plus info proyek di detail/riwayat donasi.

## Belum bisa diverifikasi
- Checkout dan field proyek di riwayat donasi: checkout membuat tagihan Xendit sungguhan, dan `simulate-paid` dimatikan di production. Untuk mengetes, nyalakan `ALLOW_SIMULATE_PAID` di staging, atau lakukan pembayaran QRIS nominal kecil.
- Google Sign-In: butuh OAuth client ID Android (SHA-1) dari tim.

## Catatan client
- Kode di `lib/data/dtos` (hasil `swagger_parser`) tidak dipakai. App memakai layer API sendiri di `lib/core/network` + `lib/models` dengan parsing toleran.
- `test/api_contract_test.dart` mem-parse respons asli yang disimpan di `test/fixtures`. Kalau bentuk respons backend berubah, test ini yang gagal duluan.
