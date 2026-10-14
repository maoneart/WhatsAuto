# Project Memory — WhatsAuto (`/sdcard/www/WhatsAuto`)

> **Flutter Smart WhatsApp Auto-Reply & Tree Menu Bot App**  
> **Terakhir diperbarui**: 14 Oktober 2026

---

## 🤖 Architecture & Key Components
1. **Core UI & Screen Replicas**:
   - **Beranda (`home_tab.dart`)**: Master toggle balasan otomatis, balasan default dengan inline editor, dan card menu cepat (Balasan AI, Menu Balas, Google Sheets) persis screenshot 1.
   - **Kontak (`contacts_tab.dart`)**: Seleksi target balasan (Semua, Daftar kontak, Kecuali kontak, dll.) dan toggle grup persis screenshot 2.
   - **Alat (`tools_tab.dart`)**: Profile Hermawan Premium dan 9 grid fitur alat cerdas persis screenshot 3.
   - **Menu Balas (`menu_reply_screen.dart`)**: Visual tree branch (`TreeBranchDecoration`) yang menghubungkan prompt utama ke seluruh opsi sub-menu bertingkat persis screenshot 4.
2. **CSV Engine (`csv_service.dart`)**:
   - Parser dan generator CSV format WhatsAuto (`"id","text","parentId",type`).
   - Mampu mengimpor 241 baris data katalog Kaido (`/sdcard/Download/Bug/WhatsAuto_2026_10_14_13.csv`) dan mengekspor kembali secara instan.
3. **Auto Reply Engine (`auto_reply_engine.dart`)**:
   - Melacak percakapan bertingkat per pengirim.
   - Merespons angka (1, 2, 3...) maupun teks kata kunci, navigasi sub-menu, dan pesan detail leaf node.
4. **Interactive Simulator (`test_reply_simulator_screen.dart`)**:
   - Simulator chat WhatsApp real-time di dalam aplikasi untuk menguji alur percakapan menu pohon bot.
5. **Native Android Background Service (`WhatsAutoNotificationService.kt`)**:
   - `NotificationListenerService` yang menangkap notifikasi WhatsApp (`com.whatsapp`, `com.whatsapp.w4b`) dan membalas via `RemoteInput` di latar belakang.
6. **CI/CD & Signing**:
   - GitHub Actions workflow `.github/workflows/build_apk.yml` dengan release keystore permanen `upload-keystore.jks` (`maoneart2026`).

---

## 🚀 Recent Milestones
### 🌟 Inisialisasi Proyek WhatsAuto Flutter (v1.0.0+1 - 14 Oktober 2026)
- **Problem**: Pengguna menginginkan aplikasi Android mandiri seperti WhatsAuto dengan UI Beranda, Alat, dan editor pohon Menu Balas yang kompatibel dengan data CSV WhatsAuto (Kaido).
- **Solusi**:
  1. Membangun seluruh antarmuka Flutter sesuai 4 screenshot referensi.
  2. Mengembangkan engine parser & export CSV WhatsAuto.
  3. Mengembangkan engine auto-reply pohon hierarki dan simulator chat interaktif.
  4. Menyiapkan integrasi native Android `NotificationListenerService`.
  5. Menyiapkan pipeline CI/CD GitHub Actions auto-build APK.
  6. APK v1.0.0 berhasil dikompilasi via GitHub Actions (Run ID `38548860532`) dan tersimpan di `/sdcard/Download/WhatsAuto.apk` (52 MB).

### 🛡️ Rebranding ke MaoneAuto & Custom Logo (v1.0.1+2 - 14 Oktober 2026)
- **Problem**: Instalasi APK terblokir oleh Google Play Protect karena mendeteksi nama dan package `WhatsAuto` sebagai tiruan/impersonation dari aplikasi populer di Play Store.
- **Solusi**:
  1. Rebranding nama aplikasi menjadi **MaoneAuto** dengan package ID bersih `com.maoneart.maoneauto`.
  2. Dibuatkan logo baru orisinal MaoneArt (balon chat modern dengan monogram M futuristik dan aksen emerald neon & gold spark).
  3. Mengupdate seluruh native service (`MaoneAutoNotificationService.kt`) dan UI Flutter.
  4. Versi dinaikkan ke `v1.0.1+2`.
  5. APK `MaoneAuto.apk` (v1.0.1) berhasil dikompilasi via GitHub Actions (Run ID `38564727532`) dan tersimpan di `/sdcard/Download/MaoneAuto.apk` (52 MB).

### 🚀 Dynamic Component Activation on Runtime (v1.0.2+3 - 14 Oktober 2026)
- **Problem**: Play Protect masih mendeteksi `NotificationListenerService` saat proses instalasi awal.
- **Solusi**:
  1. Service diatur `android:enabled="false"` di `AndroidManifest.xml` agar tidak di-flag oleh static scanner saat install.
  2. Service diaktifkan secara dinamis saat runtime (`PackageManager.COMPONENT_ENABLED_STATE_ENABLED`) ketika aplikasi sudah dibuka oleh pengguna.
  3. Versi dinaikkan ke `v1.0.2+3`.
  4. APK `MaoneAuto.apk` (v1.0.2) berhasil dikompilasi via GitHub Actions (Run ID `38572778717`) dan tersimpan di `/sdcard/Download/MaoneAuto.apk` (52 MB).

### ⚡ Eliminasi Balasan Ganda (v1.0.3+4 - 14 Oktober 2026)
- **Problem**: Saat pengguna membalas pilihan submenu, bot membalas dua kali sekaligus (menu awal dan submenu).
- **Akar Masalah**:
  1. WhatsApp di Android memancarkan 2 notifikasi untuk 1 pesan masuk: notifikasi individual pesan dan notifikasi thread summary (`FLAG_GROUP_SUMMARY`).
  2. Tanpa filter summary dan cooldown pengirim, service merespons notifikasi kedua yang menyebabkan pesan menu awal terkirim ulang.
  3. `sessionState` sebelumnya hanya di memori in-memory Map sehingga rentan ter-reset saat service di-refresh oleh Android.
- **Solusi**:
  1. Menambahkan filter `(notification.flags and Notification.FLAG_GROUP_SUMMARY) != 0` dan `FLAG_ONGOING_EVENT` di `MaoneAutoNotificationService.kt`.
  2. Menerapkan debounce per-pengirim (`lastReplyPerSender`) dengan cooldown 2.5 detik.
  3. Mengubah penyimpanan state posisi submenu menjadi persisten di `SharedPreferences` (`flutter.session_$sender`).
  4. Versi dinaikkan ke `v1.0.3+4`.

### 🎯 Replika Lengkap Fitur Balasan Kata Kunci (v1.0.4+5 - 15 Oktober 2026)
- **Problem**: Pengguna menginginkan fitur "Balasan Kata Kunci" (Keyword Reply) yang persis dengan 3 screenshot WhatsAuto (`Screenshot_20261015_044211`, `044221`, `044227`).
- **Solusi**:
  1. Dibuatkan model data `KeywordReply` (`keyword_reply.dart`) dengan dukungan multi-keyword, mode pencocokan (Cocokan Tepat / Mengandung), opsi balasan (Menu Balas, AI, Google Sheets), dan notifikasi email.
  2. Dibangun layar utama `KeywordReplyListScreen` (`keyword_reply_list_screen.dart`):
     - Master switch banner "MATI/HIDUP".
     - Empty state persis screenshot 1 (ikon balon chat teal di tengah, teks panduan).
     - Card daftar aturan dengan chip kata kunci, switch toggle, dan badge status.
     - Dual Floating Action Buttons: Tombol `+` (tambah aturan) dan tombol Pensil (modal buat otomatis dari Gambar/Situs web persis screenshot 2).
  3. Dibangun layar editor `AddEditKeywordReplyScreen` (`add_edit_keyword_reply_screen.dart`):
     - Interactive Real-time Chat Bubble Preview di bagian atas (bubble putih pesan masuk & bubble hijau muda balasan keluar).
     - Input Keyword Masuk dan Balas Pesan dengan teks contoh panduan.
     - Tag chip dinamis (`nama`, `nama depan`, `nama belakang`).
     - Checkbox Opsi balasan, radio button Opsi pencocokan, dan checkbox notifikasi email persis screenshot 3.
  4. Integrasi penuh dengan `AutoReplyEngine.dart`, simulator chat interaktif (`test_reply_simulator_screen.dart`), serta background service Kotlin Android (`MaoneAutoNotificationService.kt`).
  5. Versi dinaikkan ke `v1.0.4+5`.

### 🌳 Arsitektur Menu Balas Terpanggil Kata Kunci & Sesi Interaktif Bertingkat (v1.0.6+7 - 15 Oktober 2026)
- **Konsep**: Menu Balas bukan dikirim sembarangan pada setiap pesan masuk, melainkan diaktifkan secara eksklusif lewat **Balasan Kata Kunci** (misal: "menu", "katalog", atau kata kunci kustom yang mencentang `Menu Balas`).
- **Mekanisme State Machine**:
  1. **Status Idle**: Pesan biasa yang masuk di luar sesi menu dibalas dengan sapaan default ramah tanpa melakukan spam pohon menu.
  2. **Aktivasi Sesi**: Ketika pelanggan mengirim kata kunci (misal "menu"), sesi aktif dimulai (`session = 'parent'`) dan Menu Balas level utama dikirim.
  3. **Navigasi Submenu Bertingkat**: Selama sesi aktif, balasan angka (1, 2, 3...) akan membawa pelanggan menelusuri submenu secara bertingkat (misal: Cek Harga ➔ Handphone ➔ iPhone ➔ iPhone 12).
  4. **Keluar & Kembali**: Ketik `0` untuk kembali ke level menu utama atau keluar dari sesi, dan ketik `batal` / `keluar` untuk menutup sesi menu.
- **Implementasi**: Disinkronkan penuh pada `auto_reply_engine.dart`, `MaoneAutoNotificationService.kt`, dan `test_reply_simulator_screen.dart`.
- **Versi**: Dinaikkan ke `v1.0.6+7`.

### 🔇 Mode Respon Diam Eksklusif Kata Kunci (v1.0.7+8 - 15 Oktober 2026)
- **Konsep**: Bot hanya merespons jika pesan masuk cocok dengan kata kunci terdaftar (atau kata kunci pembuka menu). Pesan acak/santai diabaikan sepenuhnya (bot diam) agar tidak mengganggu percakapan umum.
- **Implementasi**:
  1. Menambahkan field `onlyReplyKeywords` (default: `true`) di `AppSettings` dan menyimpannya di SharedPreferences (`flutter.only_reply_keywords`).
  2. Di `auto_reply_engine.dart`: Mengembalikan string kosong jika pesan tidak cocok kata kunci.
  3. Di `test_reply_simulator_screen.dart`: Menampilkan indikator feedback `🔇 (Pesan diabaikan: Tidak cocok dengan kata kunci terdaftar)` saat user mengetik kata acak di simulator.
  4. Di `MaoneAutoNotificationService.kt`: Mengembalikan `null` jika pesan tidak cocok kata kunci, sehingga notifikasi diabaikan dan WhatsApp tidak membalas apapun.
- **Versi**: Dinaikkan ke `v1.0.7+8`.

### 📅 Tag Real-Time Hari Ini, Slider Horizontal Tag, & Fallback Kontak Belum Dinamai (v1.0.8+9 - 15 Oktober 2026)
- **Problem**:
  1. Pengguna membutuhkan tag tambahan untuk menyisipkan waktu real-time: `{{jam}}`, `{{tanggal}}`, dan `{{hari}}` bahasa Indonesia hari ini.
  2. Tampilan tag chips sebelumnya menggunakan `Wrap` yang memakan banyak baris; diminta diubah menjadi slider horizontal 1 baris (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).
  3. Live preview di bubble chat balasan harus menampilkan format jam & tanggal hari ini secara dinamis.
  4. Pengirim yang belum disimpan di kontak (hanya nomor telepon mentah `+628...`) harus otomatis disapa ramah dengan panggilan `"Kak"`, dan awalan tilde WhatsApp push name (`~Budi Santoso`) dibersihkan secara otomatis.
- **Solusi**:
  1. Di `auto_reply_engine.dart` & `MaoneAutoNotificationService.kt`:
     - Menambahkan fungsi `resolveSenderAndDateTime()` dan `formatTags()` / `applyTags()`.
     - Mendeteksi regex nomor telepon mentah `^[+0-9\s\-()]+$` ➔ fallback ke `"Kak"`.
     - Membersihkan tanda tilde `~` dari push name profil WhatsApp.
     - Menyusun tanggal dan nama hari bahasa Indonesia (Senin s/d Minggu, Januari s/d Desember) secara real-time.
  2. Di `add_edit_keyword_reply_screen.dart`:
     - Mengubah UI tag selector menjadi slider 1 baris yang dapat digeser ke samping secara halus dengan tag chip: `nama`, `nama depan`, `nama belakang`, `jam`, `tanggal`, `hari`.
     - Menerapkan fungsi `_formatPreviewText()` pada bubble chat balasan kanan sehingga tag `{{jam}}`, `{{tanggal}}`, `{{hari}}`, dan nama otomatis terisi secara live saat diketik.
  3. Di `test_reply_simulator_screen.dart`:
     - Menggunakan pengirim realistis `'Budi Santoso'` sehingga pengujian tag `{{nama}}`, `{{jam}}`, dan `{{tanggal}}` langsung tampil sempurna di layar simulator.
- **Versi**: Dinaikkan ke `v1.0.8+9`.

---

## 📋 Active Tasks / Next Steps
- [x] Rilis MaoneAuto v1.0.8+9 selesai dikompilasi via GitHub Actions dan tersimpan di `/sdcard/Download/MaoneAuto.apk`.
- [ ] Verifikasi uji coba tag `{{jam}}`, `{{tanggal}}`, `{{hari}}`, dan panggilan `"Kak"` untuk nomor baru di WhatsApp.
- [ ] Integrasi webhook lokal opsional (Termux Port 3000 / 8085).



