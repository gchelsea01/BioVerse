# Catatan Backend untuk App Android

API: `https://api.ourprojects.my.id/v1` (health OK, DB connected).
Masalah yang ditemukan saat menyambungkan layar Figma ke API, urut dari yang paling berdampak.

## Perlu diperbaiki (memblokir layar Figma)

1. **`DonationDetail` tidak punya info proyek.**
   Riwayat donasi di Figma menampilkan nama proyek, lokasi tanam, jumlah fragmen, dan "time since planting". Response `/app/donations/history` hanya berisi uang dan status.
   → Tambahkan `project_id`, `project_title`, `project_category`, `image_url`, `quantity`, `planted_at` (atau `adopted_coral_ids`).
   *Sementara:* app memakai `/app/conservation/corals/my` untuk detail karang. Donasi pohon/mangrove hanya tampil sebagai transaksi.

2. **Tidak ada `DonationType` untuk mangrove.**
   `ProjectCategory` punya `mangrove`, tapi `DonationType` hanya `coral_adoption`, `tree_planting`, dan lainnya.
   → Tambahkan `mangrove_planting`, atau satu tipe generik `unit_adoption` yang mengikuti kategori proyek.
   *Sementara:* proyek mangrove dikirim sebagai `tree_planting`.

3. **`/app/conservation/corals/my` hanya untuk karang.**
   Tidak ada endpoint "pohon/mangrove saya" beserta foto berkala.
   → Generalisasi menjadi `/app/conservation/units/my` untuk semua kategori, termasuk timeline foto bulan 1/3/6.

4. **Misi tidak punya riwayat submission per user.**
   Hanya ada `GET /mission-submissions/{id}`, jadi app tidak tahu misi mana yang sudah dikerjakan, dan "Missions Completed" di Profile tidak bisa dihitung.
   → Tambahkan `GET /app/mission-submissions/my`, atau field `my_last_submission_status` di `EcoMission`.

5. **`ConservationProject` tidak punya lokasi.**
   Figma menampilkan "Planting Location: Raja Ampat".
   → Tambahkan `location_name` (dan opsional `lat`/`lng`). Field `contributors_count` juga dipakai di Figma.

## Sebaiknya ditambah

6. **Stat profil.** Figma menampilkan Total Donation, Missions Completed, dan Total Points.
   → Tambahkan `GET /app/users/me/stats`. Saat ini app menghitung jumlah donasi sendiri dari list.
7. **Field `EcoMission`** perlu `image_url` dan `estimated_minutes` (Figma menampilkan foto + "5 Minutes").
8. **Daftar jenis pet.** `CreatePetRequest` menerima `pet_species`/`coral_type` bebas (string).
   → Tambahkan enum atau endpoint `/app/pets/species` agar pilihan pet tidak di-hardcode di app.
9. **Notifikasi** hanya punya `limit`, tanpa `cursor`. Tidak bisa paginasi.
10. **`servers` di `openapi.yaml`** masih `api.bioverse.id`/`staging-api.bioverse.id`, bukan URL deploy sebenarnya. Client hasil generate akan salah URL.
11. **Seed data.** Baru 1 proyek (coral) dan 0 berita. Tambahkan minimal 1 proyek mangrove + 1 tree + beberapa berita untuk demo/testing.
12. **Kurva XP pet** tidak diekspos. App mengasumsikan 100 XP per level untuk progress bar. Tambahkan `xp_to_next_level` di `VirtualPet`.
13. **Google Sign-In** butuh OAuth client ID Android (SHA-1) dari tim. Tombol Google belum dipasang supaya tidak ada tombol mati.
14. **Leaderboard** hanya dalam USD (`total_donations_usd`). User Indonesia lebih cocok IDR, atau ikut `preferred_currency_code`.

## Catatan client
- Kode di `lib/data/dtos` (hasil `swagger_parser`) butuh paket `retrofit` + `build_runner` dan tidak dipakai app ini. App memakai layer API sendiri di `lib/core/network` + `lib/models`, dengan parsing toleran (field null tidak membuat crash). Folder `lib/data/dtos` boleh dihapus atau dibiarkan.
