# Kebutuhan Aset BioVerse (App Android)

Ringkas: apa yang **harus dibuat artist**, apa yang **sudah dibuatkan di kode**, dan apa yang **cukup diambil dari Figma**.

BioVerse bukan cuma laut. Semua aset harus siap untuk 3 ekosistem dari backend: **coral (terumbu karang), mangrove, tree (hutan/darat)**.

---

## A. Wajib dibuat artist

Gaya umum: flat 2D, bentuk bulat dan lembut, sedikit gradasi, mengikuti maskot coral biru di Figma. Export **PNG transparan @3x** (atau SVG kalau tanpa efek). Simpan di `bioverse_app/assets/images/...` dengan nama persis seperti di bawah.

### 1. Maskot virtual pet (paling penting)
Pet adalah inti gamifikasi. Feedback user: sistem pet belum jelas, jadi pet harus **kelihatan tumbuh**.

| Yang dibuat | Jumlah | Keterangan |
|---|---|---|
| Pet coral | 4 tahap | `pet_coral_hatchling.png`, `_juvenile`, `_adult`, `_elder`. Dari kuncup kecil sampai coral besar bercabang. |
| Pet mangrove | 4 tahap | `pet_mangrove_*.png`. Bibit dengan akar napas, lalu pohon mangrove kecil berwajah. |
| Pet tree | 4 tahap | `pet_tree_*.png`. Biji/tunas, lalu pohon kecil berwajah. |
| Ekspresi | 3 per spesies | `pet_<spesies>_happy`, `_sad` (health < 40%), `_sleepy` (belum diurus hari ini). Cukup untuk tahap adult; tahap lain pakai versi normal. |

- Ukuran kanvas 512×512, karakter di tengah, ada ruang kosong ±10%.
- Tahap pertumbuhan sesuai backend: `hatchling → juvenile → adult → elder`.

### 2. Background habitat pet
Dipakai di kartu pet (Home & tab Pet). Juga dijual di shop (`habitat_background`).
- `habitat_reef.png` (bawah laut), `habitat_mangrove.png` (pantai berlumpur, akar), `habitat_forest.png` (hutan/bukit).
- 1080×720, warna lembut supaya pet tetap menonjol.

### 3. Ilustrasi onboarding (3 halaman)
Menjawab feedback "buka app bingung app-nya buat apa".
1. `onboard_donate.png`: tangan menanam bibit/karang. Pesan: *Donasi untuk restorasi alam*.
2. `onboard_track.png`: HP dengan foto perkembangan bulan 1/3/6. Pesan: *Pantau hasilnya dengan foto nyata*.
3. `onboard_pet.png`: pet coral, mangrove, dan tree bersama. Pesan: *Rawat pet, selesaikan misi ramah lingkungan*.
- 800×800, transparan.

### 4. Item shop (kosmetik pet)
Backend punya tipe `pet_skin`, `pet_accessory`, `habitat_background`, `streak_freeze`, `xp_boost_item`. Admin mengisi `preview_asset_url`. Sebagai awal, sediakan:
- 3 aksesori: topi, kacamata, syal (`acc_hat.png`, ...), 256×256.
- Ikon `streak_freeze` (es batu/perisai) dan `xp_boost` (ramuan), 256×256.

### 5. App icon & logo
- Logo BioVerse (infinity + daun + coral) sudah ada di Figma. Export **SVG** sebagai `logo.svg` dan versi ikon saja `logo_mark.svg`.
- App icon Android: logo mark di atas background putih/teal, 1024×1024, ditambah versi *adaptive* (foreground + background terpisah).

---

## B. Sudah dibuatkan di kode (tidak perlu artist)
- Ikon UI (home, donasi, pet, profil, koin, streak, kamera, dll.) memakai Material Icons.
- Ikon kategori coral / mangrove / tree.
- Placeholder pet: karakter vektor sederhana digambar dengan kode, dengan warna per spesies dan ukuran per tahap. Begitu PNG dari bagian A.1 masuk, placeholder otomatis diganti.
- Empty state, loading, dan error state.
- Badge status (Active, Expired, Paid, Pending, dll.).
- QR code QRIS di-render dari string backend (tidak perlu gambar).

## C. Dari backend (bukan aset app)
- Foto proyek (`image_url`), foto berkala karang/pohon (`photo_url` bulan 1/3/6), thumbnail berita, avatar user. Semua diunggah admin atau operator lapangan.
- Catatan: data seed sekarang baru 1 proyek dan 0 berita. Tolong admin isi minimal 1 proyek per kategori (coral, mangrove, tree) supaya semua layar bisa dites.

---

## D. Prioritas
1. Pet coral 4 tahap + habitat reef (layar Home dan Pet langsung butuh).
2. Ilustrasi onboarding 3 halaman.
3. Pet mangrove + tree, ekspresi.
4. Item shop.
5. App icon final.
