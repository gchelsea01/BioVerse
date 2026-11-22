# BioVerse – App Android (Flutter)

App B2C BioVerse: donasi restorasi coral, mangrove, dan pohon. Progres dipantau lewat foto berkala, ditambah virtual pet yang tumbuh lewat eco-mission.

## Menjalankan

```powershell
flutter pub get
flutter run
```

- API default: `https://api.ourprojects.my.id/v1`. Untuk backend lokal (emulator):
  `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/v1`
- Di Windows, aktifkan **Developer Mode** (Settings → System → For developers) supaya plugin bisa di-build (butuh symlink).

## Struktur

```
lib/
  core/       theme, API client (token refresh), formatter, widget bersama
  models/     model JSON (parsing toleran)
  services/   satu kelas per kelompok endpoint
  state/      Session (login, poin, streak, pet) + registry Services
  features/   onboarding, auth, home, projects, donation, pet, missions, profile, shell
assets/images/  taruh PNG dari artist di sini (lihat ../docs/ASSETS.md)
```

`lib/data/dtos` (hasil swagger_parser) tidak dipakai. Alasannya ada di `../docs/BACKEND_NOTES.md`.

## Tindak lanjut feedback usability testing

| Feedback | Perubahan |
|---|---|
| Sistem virtual pet belum jelas | Tab Pet menampilkan health, XP ke level berikutnya, 4 tahap tumbuh, tombol Feed/Clean/Play, kartu "How your pet grows", dan pilihan spesies coral/mangrove/tree saat adopsi |
| Homepage kurang minimalis | Home hanya 5 blok: kontribusi kamu, pet, 1 misi hari ini, proyek, dampak komunitas |
| Button kurang kontras | Warna primary digelapkan (rasio kontras 5.6:1); semua tombol utama berbentuk filled dan full-width |
| Alur subscription membingungkan | Pilihan "One-time" vs "Monthly" ada penjelasannya, layar setup memuat 4 langkah cara kerja, dan pause/cancel tersedia di Profile → Monthly support |
| Tombol Home tidak terlihat seperti tombol | Bottom navigation memakai ikon + label dan indikator aktif |
| Tombol hilang / tidak bisa ditekan | Tombol aksi selalu ada di bawah layar dengan state loading; tidak ada tombol tanpa fungsi |
| Navigasi ke quest pet | Misi bisa diakses dari Home, tab Pet, dan layar "All missions" |
| Report donasi bulan ke-2 atau ke-3? | Timeline diberi label "Month 1/3/6", "Report x of 3", dan tanggal; foto diberi label bulan |
| Buka app bingung ini app apa | Splash dengan tagline + onboarding 3 langkah (Donate → Track → Pet) |
