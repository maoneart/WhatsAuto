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
