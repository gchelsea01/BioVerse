# Catatan Backend untuk App Android

API: `https://api.ourprojects.my.id/v1`. Terakhir dicek 23 Nov 2026 pada backend commit `e8f1166` (sudah ter-deploy), memakai akun tes `bioverse.qa+…@example.com`.

## Masih terbuka

1. **Fallback CV masih auto-approve di production.** Sekarang sudah ada guard `CV_FALLBACK_AUTO_APPROVE`, tapi nilai default-nya `true`. Tes 23 Nov: PNG polos berwarna hijau tetap `verified` dan mendapat +50 poin.
   - Kalau fitur ini sudah dipakai user sungguhan, set `CV_FALLBACK_AUTO_APPROVE=false` di server (submission akan masuk `needs_review`) dan sediakan halaman review di admin. Atau nyalakan service CV.

2. **`completed_today` memakai `CURRENT_DATE` (tanggal server, UTC)**, sedangkan `submission_date` memakai tanggal lokal user. Akibatnya, untuk misi yang di-submit antara 00:00–07:00 WIB, `completed_today` bisa `false` padahal submit ulang ditolak 409.
   - Perbaikan: bandingkan dengan tanggal lokal user, bukan `CURRENT_DATE`.

3. **`/v1/health` sepertinya di-cache.** `timestamp` dan `uptime` di respons tertinggal beberapa jam, jadi endpoint ini tidak bisa dipakai untuk memastikan deploy.

## Sudah beres (diverifikasi di API live)
- `completed_today` / `my_last_submission_status` di `GET /missions` sudah terisi (fix `COALESCE`).
- Pesan receipt submit misi sudah sesuai status ("Proof photo verified successfully.").
- `units/my` tidak lagi mengarang foto "verified". Placeholder sekarang `health_status: "scheduled"`, `is_verified_healthy: false`, memakai foto proyek. App tidak pernah menghitungnya sebagai laporan diterima.
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
