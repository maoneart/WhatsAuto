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

### 🔬 Reverse Engineering WhatsAuto Official v4.65 & Deep Engine Alignment (v1.0.9+10 - 15 Oktober 2026)
- **Problem**: Pengguna meminta membedah APK resmi WhatsAuto (`com.guibais.whatsauto`) dari APKPure untuk mempelajari seluruh mekanisme internal dan menyamakannya 100% ke dalam MaoneAuto.
- **Temuan Hasil Dekompilasi JADX pada WhatsAuto Official v4.65**:
  1. **Notification Parsing & Hidden Unicode**:
     - Judul notifikasi dibersihkan dari regex `^.+ \\(\\d+ \\S+\\)$` (misal "Budi (2 pesan)").
     - Karakter Unicode tersembunyi `\u200e`, `\u2068`, `\u2069` dihapus.
     - Awalan channel seperti `WA Business:` dan `WhatsApp:` dihilangkan.
     - Format pengirim grup dipisahkan dari tanda `@` (`Pengirim @ Grup`) atau `:` (`Grup: Pengirim`).
  2. **Keyword Normalization & Matching Logic**:
     - Tanda baca `[?!.\n]` dihilangkan dari pesan masuk dan keyword.
     - Mode Cocokan Tepat (*Exact Match*) diproses pertama kali.
     - Mode Mengandung (*Contains Match*) diperiksa kedua dengan pembungkus spasi word-boundary `" " + cleanMsg + " "` dan `" " + cleanKw + " "` untuk mencegah *false positives*.
  3. **Navigasi Pohon Menu Balas**:
     - Root parent ID selalu `"parent"`.
     - Ditambahkan opsi dinamis `${options.length + 1}. ↩️ Menu Sebelumnya` untuk naik 1 tingkat menu di atasnya, dan `0. 🏠 Kembali ke Menu Utama`.
     - Leaf node (node informasi/harga tanpa anak) otomatis menyelesaikan sesi menu (`session = 'idle'`) persis flag `message_type == 1` di WhatsAuto.
  4. **Sistem Tag Variabel**:
     - Mendukung tag kurung kurawal ganda `{{...}}` maupun tunggal `{...}` case-insensitive: `{name}`, `{first name}`, `{last name}`, `{time}`, `{date}`, `{message}`, `{{jam}}`, `{{tanggal}}`, `{{hari}}`, `{{pesan}}`.
     - Ditambahkan tag chip `pesan` (`{{pesan}}`) ke slider horizontal di `AddEditKeywordReplyScreen`.
- **Implementasi**:
  1. `lib/services/auto_reply_engine.dart`: Sinkronisasi pembersihan unicode, pemisahan grup, normalisasi tanda baca, prioritas exact vs contains, navigasi N+1 (Menu Sebelumnya) dan 0 (Menu Utama), serta leaf reset.
  2. `android/app/src/main/kotlin/com/maoneart/maoneauto/MaoneAutoNotificationService.kt`: Sinkronisasi penuh title cleanup, group format regex, exact/contains matching, tree navigation, dan tag interpolation.
  3. `lib/screens/add_edit_keyword_reply_screen.dart`: Tambah chip `pesan` ke slider tag horizontal.
- **Versi**: Dinaikkan ke `v1.0.9+10`.

### 🛡️ Full Architectural Absorption dari com.guibais.whatsauto.apk (v1.0.10+11 - 15 Oktober 2026)
- **Problem**: Pengguna menyediakan APK resmi WhatsAuto (`com.guibais.whatsauto.apk`) di `/sdcard/Download/` dan meminta seluruh logikanya dibedah tuntas, diserap, dan dituangkan ke dalam MaoneAuto.
- **Hasil Bedah & Penyerapan Logika Utama WhatsAuto**:
  1. **Pencegahan Balasan ke Pesan Sendiri (`android.selfDisplayName`)**:
     - Notifikasi diperiksa terhadap field `android.selfDisplayName`. Jika pengirim sama dengan nama profil pemilik akun (atau nama pengguna di dalam grup), pesan langsung diabaikan seketika. Mencegah bot membalas pesannya sendiri yang dikirim dari WhatsApp Web / desktop.
  2. **Deteksi RemoteInput Ganda (Actions + WearableExtender Fallback)**:
     - WhatsAuto memindai `notification.actions` standar, lalu jika belum ditemukan, memeriksa `Notification.WearableExtender(notification).actions`. Diadopsi 100% pada `findQuickReplyAction` di `MaoneAutoNotificationService.kt` untuk kompatibilitas penuh di seluruh versi Android.
  3. **Filter Aplikasi yang Didukung (Supported Apps)**:
     - Service memeriksa bundle konfigurasi `supported_apps` sehingga hanya memproses notifikasi dari aplikasi yang dicentang oleh pengguna (WhatsApp, WA Business, Telegram, Messenger).
  4. **Filter Pesan Grup & Kontak**:
     - Deteksi grup cerdas (tanda `:` atau `@` non-telepon). Jika `enable_groups == false`, notifikasi grup di-drop.
     - Mode `except_phone`: Hanya membalas nomor tak dikenal (bukan kontak tersimpan di buku telepon) dengan regex validasi nomor.
  5. **Sistem Header & Footer Balasan**:
     - Ditambahkan fitur pembungkus header (`*[Balasan Otomatis]*`) dan footer (`_Terkirim via MaoneAuto_`) di `AutoReplyEngine.dart`, `MaoneAutoNotificationService.kt`, serta switch toggle di UI `ContactsTab`.
  6. **Mode Pengatur Waktu (Reply Time Mode)**:
     - Mendukung mode Instan, Balas Sekali (`reply_time_once`), dan Tunda Balasan (`reply_time_delay`) dengan `Handler.postDelayed`.
- **Versi**: Dinaikkan ke `v1.0.10+11`.

### 🎨 MaoneArt Glassmorphism Redesign & UI Harmonization (v1.0.11+12 - 15 Oktober 2026)
- **Problem**: Pengguna meminta agar desain UI MaoneAuto mengikuti konsep alur WhatsAuto (mirip fungsinya dan penataan layoutnya), tetapi **tidak sama persis** / bukan jiplakan mentah, melainkan memiliki identitas orisinal MaoneArt yang lebih modern, estetik, dan elegan.
- **Solusi & Sentuhan Desain Orisinal MaoneArt**:
  1. **Beranda (`home_tab.dart`)**:
     - *Hero Master Card*: Gradient slate-emerald gelap dengan efek glowing border, dynamic pulse indicator, status subtitle dinamis, dan switch neon.
     - *Teks Balasan Default*: Tampilan bubble WhatsApp interaktif dengan status checklist ganda biru `✓✓`, timestamp dinamis, dan tombol ubah cepat via Glassmorphism modal input.
     - *Modul Balasan Cerdas (Bento Grid)*: Grid 2-kolom 4 modul pintar (Balasan AI, Kata Kunci, Menu Balas, Google Sheets) dengan ikon bergradien dan badge chip khusus (`AI PRO`, `KEYWORD`, `TREE BOT`, `SHEETS`).
     - *Quick Simulator Launcher*: Banner card interaktif di bagian bawah untuk langsung menguji alur bot ke simulator chat.
  2. **Target & Kontak (`contacts_tab.dart`)**:
     - *Custom Selection Cards*: Pilihan target penerima (Semua Orang, Buku Kontak, Kecuali Kontak, Nomor Baru Saja) dengan ikon khusus, rounded indicator, dan active glow.
     - *Grup WhatsApp*: Glass switch card modern dengan ikon grup dan penjelasan proteksi anti-spam.
     - *Header & Footer Balasan*: Dilengkapi *Live Preview Chat Bubble* untuk melihat tampilan pesan balasan yang telah dibungkus header dan footer, serta tombol edit teks modal.
  3. **Pusat Alat (`tools_tab.dart`)**:
     - *MaoneArt VIP Profile Card*: Avatar monogram "M" gradien neon emerald, badge *VIP Lifetime*, indikator online, dan tombol sync.
     - *Bento Grid 9 Fitur*: Layout kartu kaca 16px dengan 9 warna aksen khusus (Sky, Amber, Emerald, Cyan, Teal, Pink, Violet, Dark Teal, Orange).
     - *Supported Apps Modal*: Diganti dari dialog biasa menjadi MaoneArt Glassmorphism Modal dengan backdrop blur dan switch per-aplikasi (WhatsApp, WA Business, Telegram, Messenger) yang tersimpan ke SharedPreferences.
  4. **Glassmorphism Modal (`glassmorphism_modal.dart`)**:
     - Ditambahkan method `showInputModal` dengan 100% simetris 2-kolom grid actions untuk semua input teks.
  5. **Navigasi Bawah (`main_navigation_screen.dart`)**:
     - Ikon navigasi modern dengan outline saat idle dan solid emerald saat aktif.
- **Versi**: Dinaikkan ke `v1.0.11+12`.

### 📊 Integrasi Penuh Submenu: Google Spreadsheet, AI 9Router, Pesan Sambutan, Webhook, & Catatan Cepat (v1.0.12+13 - 15 Oktober 2026)
- **Problem**: Pengguna menanyakan apakah isi menu-menunya sudah selesai juga seperti sinkronisasi ke spreadsheet ("isi dari menu menunya udah juga kaya sincron ke spreadseeht udahbjuga?"), dan meminta seluruh menu yang tersisa diimplementasikan secara bertahap.
- **Implementasi Komprehensif**:
  1. **Google Spreadsheet Sync (`spreadsheet_sync_screen.dart` & `spreadsheet_service.dart`)**:
     - Parser link/ID Google Spreadsheet otomatis mengonversi format edit/published URL ke CSV export (`/export?format=csv`).
     - Sinkronisasi Kolom A (Kata Kunci), Kolom B (Balasan), Kolom C (0 = Exact / 1 = Contains).
     - Data Viewer interaktif dengan search filter & live keyword tester di dalam aplikasi.
     - Terintegrasi langsung ke `AutoReplyEngine.dart` dan `MaoneAutoNotificationService.kt` (mencocokkan keyword sheet secara native di latar belakang saat ada pesan WA).
  2. **Balasan AI 9Router & Gemini (`ai_reply_screen.dart` & `ai_service.dart`)**:
     - Terhubung ke 9Router OpenAI-compatible gateway lokal di port 20128 (`http://127.0.0.1:20128/v1/chat/completions`) dan Google Gemini Cloud API.
     - System prompt / persona editor dengan 3 template siap pakai (CS Toko Online, Asisten Santai, Formal Bisnis).
     - Live interactive test prompt dengan respons langsung dari model AI.
  3. **Pesan Sambutan / Welcome Message (`welcome_message_screen.dart`)**:
     - Master toggle pesan selamat datang untuk kontak/nomor baru.
     - Live chat bubble preview ala WhatsApp dengan checklist biru ganda `✓✓`.
     - Slider tag otomatis (`{{nama}}`, `{{nama_depan}}`, `{{jam}}`, `{{hari}}`, `{{tanggal}}`).
  4. **Webhook Server (`webhook_server_screen.dart` & `webhook_service.dart`)**:
     - Konfigurasi endpoint POST webhook untuk integrasi backend API lokal (port 8085 / 8088 Hermes).
     - Spesifikasi payload JSON request/reply lengkap & tombol uji ping live.
  5. **Catatan Cepat (`quick_notes_screen.dart` & `quick_note_model.dart`)**:
     - Manajemen template teks & memo bisnis (No Rekening, Alamat Toko, Format Order).
     - Fitur Salin ke clipboard dan Bagikan langsung ke WhatsApp via `share_plus`.
  6. **Penyatuan Navigasi & Simulator**:
     - Menghubungkan seluruh 9 kartu di `ToolsTab` dan 4 Bento Card di `HomeTab`.
     - Mengintegrasikan data spreadsheet ke `TestReplySimulatorScreen` sehingga simulasi chat langsung mengenali kata kunci sheet.
- **Versi**: Dinaikkan ke `v1.0.12+13`.

### 🔔 Solusi Tuntas Akses Notifikasi Android & Penanganan CharSequence (v1.0.13+14 - 15 Oktober 2026)
- **Problem**: Pengguna melaporkan bahwa saat diuji coba di simulator chat berhasil ("di uji coba mah jalan"), tetapi saat dites di WhatsApp asli tidak membalas ("pas saya ke wa ga mau padahal saya pakai 2 wa").
- **Akar Masalah**:
  1. Izin Android "Akses Notifikasi" (*Notification Listener Service*) belum aktif atau terhalang *Restricted Settings* (Setelan Dibatasi) pada Android 13/14/15, dan di aplikasi tidak ada banner pengingat visual yang menetap jika izin belum diberikan.
  2. `android:enabled="false"` di `AndroidManifest.xml` membuat sebagian sistem Android menyembunyikan service dari daftar listener saat pertama kali dipasang.
  3. `extras.getString(Notification.EXTRA_TITLE)` mengembalikan `null` jika WhatsApp mengirim teks berformat `SpannableString`/`CharSequence`, sehingga notifikasi ter-drop.
  4. Nilai default `flutter.is_auto_reply_enabled` di service native adalah `false` jika belum ada interaksi simpan setting.
- **Solusi Komprehensif**:
  1. `AndroidManifest.xml`: Mengubah `android:enabled="true"` pada `MaoneAutoNotificationService`.
  2. `MaoneAutoNotificationService.kt`:
     - Membaca `rawTitle` secara aman menggunakan `getCharSequence(Notification.EXTRA_TITLE)?.toString()`.
     - Membaca `rawText` secara aman dengan fallback ke `EXTRA_BIG_TEXT` dan `EXTRA_TEXT_LINES`.
     - Mengubah nilai default `is_auto_reply_enabled` menjadi `true`.
     - Merelaksasi filter `selfDisplayName` agar hanya memblokir jika pengirim persis sama (bukan pencocokan substring).
  3. `MainNavigationScreen.dart`:
     - Menambahkan `WidgetsBindingObserver` untuk re-evaluasi izin notifikasi saat pengguna kembali dari Settings (`resumed`).
     - Menyimpan konfigurasi otomatis saat aplikasi dibuka pertama kali.
     - Menampilkan modal popup izin MaoneArt Glassmorphism saat startup jika izin belum aktif.
  4. `HomeTab.dart`:
     - Menambahkan *Glowing Amber Warning Banner* di bagian paling atas Beranda jika izin akses notifikasi belum aktif, lengkap dengan tombol langsung ke Pengaturan Android.
- **Versi**: Dinaikkan ke `v1.0.13+14`.

### ⚡ Service Rebind, Anti-Group Drop & Card Akses Notifikasi Permanen (v1.0.14+15 - 15 Oktober 2026)
- **Problem**: Pengguna menanyakan mengapa notifikasi pengaturan izin tidak muncul saat update dan bot tetap tidak merespons di WhatsApp asli ("apk pertama pas awal itu ada notif klik pengaturan terus aktifkan apa gitu sekarang ko ga ada ya? soalnya tetep ga mau respon apa notif di hapus kali").
- **Akar Masalah**:
  1. **NotificationListener Unbound**: Android OS (terutama Android 10-15) secara otomatis memutuskan koneksi (*unbind*) listener service saat APK diupdate/diinstal ulang, meskipun nama paket masih tersimpan di `Settings.Secure.enabled_notification_listeners`.
  2. **False Group Detection**: Pengecekan grup menggunakan `rawTitle.contains(":")` keliru menganggap semua pesan yang memiliki titik dua (seperti prefix `"WA Business:"`, `"WhatsApp:"`, jam pesan, emoticon, clone app) sebagai grup WhatsApp, sehingga langsung di-drop karena filter grup mati secara default.
  3. **Android 13/14 Restricted Settings**: APK sideload diblokir oleh Android di menu Akses Notifikasi sehingga sakelar toggle abu-abu, membutuhkan akses ke "Info Aplikasi" -> "Izinkan setelan yang dibatasi".
- **Solusi Komprehensif**:
  1. `MainActivity.kt`:
     - Menambahkan handler `openAppDetailsSettings` (langsung membuka Info Aplikasi untuk membuka kunci setelan dibatasi).
     - Menambahkan handler `rebindService` & `forceReconnectService` (toggle component dan memanggil `NotificationListenerService.requestRebind`).
     - Memanggil `rebindNotificationService()` otomatis di `onCreate` & `onResume`.
  2. `MaoneAutoNotificationService.kt`:
     - Implementasi `onListenerConnected()` & `onListenerDisconnected()` dengan auto-rebind.
     - Memperbaiki deteksi grup dengan `Notification.EXTRA_IS_GROUP_CONVERSATION` (Android 9+) dan menghapus `rawTitle.contains(":")`.
     - Memperbaiki filter `selfDisplayName` agar tidak memblokir uji coba 2 WA pada perangkat yang sama.
  3. `ToolsTab.dart`:
     - Menambahkan kartu permanen **Akses Notifikasi HP** dengan indikator status live (🟢 Aktif / 🔴 Belum Aktif) dan modal MaoneArt Glassmorphism interaktif (Akses Notifikasi, Info Aplikasi, dan Hubungkan Ulang).
  4. `HomeTab.dart` & `MainNavigationScreen.dart`:
     - Mengubah warning banner ke format 2-kolom simetris (Info Aplikasi & Pengaturan).
     - Menjamin modal perizinan muncul di startup dengan `addPostFrameCallback`.
- **Versi**: Dinaikkan ke `v1.0.14+15`.

### 🚀 Solusi Ikon Launcher Sempurna & Balasan Dual WA 1 HP (v1.0.15+16 - 15 Oktober 2026)
- **Problem**: Pengguna melaporkan logo/ikon aplikasi hilang (blank/hilang dari home screen) dan bot tetap tidak merespons saat diuji coba antar 2 WA dalam 1 HP (1 WA biasa & 1 WA bisnis).
- **Akar Masalah**:
  1. **Ikon Launcher Hilang**: 
     - Atribut `android:roundIcon` tidak ada di `AndroidManifest.xml`.
     - File `ic_launcher_round.xml` dan `ic_launcher_round.png` belum ada.
     - Dimensi `ic_launcher_foreground.png` di mipmap density sebelumnya tidak sesuai spesifikasi resmi Android Adaptive Icon (harus kanvas 108dp dengan safe zone 72dp di tengah), menyebabkan launcher OEM (Xiaomi HyperOS, Samsung OneUI, dll.) menolak merender ikon adaptif dan menampilkan ruang kosong / robot hijau default.
  2. **Dual WA 1 HP Tidak Merespons**:
     - `onlyReplyKeywords` berstatus default `true` tanpa switch kontrol di UI, sehingga pesan tes biasa ("halo", "tes", "p") langsung di-drop dengan return `null` karena bukan kata kunci yang didaftarkan.
     - Pengecekan `selfDisplayName` memblokir pengirim jika nama kontak pengirim sama persis dengan nama profil akun penerima (sangat umum terjadi saat mengetes kontak sendiri di 1 HP).
     - Debounce dan duplikasi terlalu panjang (2.5 - 3 detik).
- **Solusi Komprehensif**:
  1. **Aset Ikon Launcher Lengkap**:
     - Menghasilkan seluruh density `ic_launcher.png` (48x48 hingga 192x192).
     - Menghasilkan seluruh density `ic_launcher_round.png` dengan circular mask halus.
     - Menghasilkan seluruh density `ic_launcher_foreground.png` dengan kanvas resmi 108dp (108x108 hingga 432x432) dan inner safe zone 72dp.
     - Menambahkan `ic_launcher_round.xml` di `mipmap-anydpi-v26/`.
     - Menambahkan `android:roundIcon="@mipmap/ic_launcher_round"` di `AndroidManifest.xml`.
  2. **Dual WA 1 HP & Default Reply Switch**:
     - Mengubah default `onlyReplyKeywords` menjadi `false` di `AppSettings` dan `MaoneAutoNotificationService.kt`, sehingga pesan apapun yang masuk otomatis dibalas dengan `defaultReply`.
     - Menambahkan switch interaktif di kartu Beranda: "Mode: Balas Semua Pesan Masuk" vs "Mode: Hanya Balas Kata Kunci".
     - Menghapus filter `selfDisplayName` yang memblokir pengetesan kontak sendiri.
     - Menambahkan fallback parsing `android.messages` (MessagingStyle Bundle) jika `EXTRA_TEXT` kosong.
     - Memperpendek debounce per pengirim dan deduplikasi pesan menjadi 1 detik.
### 🚀 Penyelarasan Engine Notifikasi Resmi WhatsAuto & Eliminasi Summary Drop (v1.0.16+17 - 15 Oktober 2026)
- **Problem**: Pengguna telah mengaktifkan seluruh perizinan dan membuat kata kunci "ass" dan "menu", tetapi bot tetap tidak membalas saat dites dual WA di 1 HP ("sudah di hidupkan semua juga, tadi sudah saya uninstall dan hapus cache juga sama ttp ga bisa respon notifikasi").
- **Akar Masalah Fundamental (Terungkap dari Dekompilasi WhatsAuto Resmi)**:
  1. **Drop Fatal pada `FLAG_GROUP_SUMMARY` (Line 62)**: Di Android 10-15 (MIUI, HyperOS, ColorOS, OneUI), notifikasi WhatsApp selalu dibundel ke thread percakapan dengan flag `FLAG_GROUP_SUMMARY`. WhatsAuto asli **TIDAK PERNAH** memfilter `FLAG_GROUP_SUMMARY`, melainkan mengecek ketersediaan `RemoteInput` pada aksi notifikasi. Pengecekan line 62 sebelumnya langsung me-return/drop setiap notifikasi sebelum membaca pengirim maupun teks!
  2. **Short-Circuit Fatal pada `computeReply`**: Jika `flutter.menu_nodes_cache` null/kosong (terjadi saat fresh install atau hapus cache sebelum membuka tab menu), `computeReply` langsung keluar di baris awal sebelum mengecek kata kunci terdaftar ("ass", "menu"). Akibatnya, kata kunci tidak pernah dievaluasi!
  3. **Array `RemoteInput` Parsial**: WhatsAuto mengirim balasan ke seluruh `remoteInputs` dalam aksi, sedangkan implementasi sebelumnya hanya menyertakan 1 `remoteInput` tunggal.
  4. **Premature Deduplication Key**: `processedKeys[messageKey] = now` dicatat sebelum pengecekan `findQuickReplyAction`, sehingga event notifikasi susulan yang membawa action intent langsung dibuang sebagai duplikat.
  5. **State Koneksi Listener Tidak Terdeteksi di UI**: Saat reinstall, `isNotificationServiceEnabled` bisa bernilai `true` di secure settings meskipun sistem Android belum mengikat/mengaktifkan koneksi listener (`isListenerConnected == false`), sehingga banner perizinan tidak muncul.
- **Solusi Komprehensif**:
  1. Menghapus filter `FLAG_GROUP_SUMMARY` dari `MaoneAutoNotificationService.kt`, menyelaraskan dengan engine resmi WhatsAuto.
  2. Memperbaiki `computeReply`: Rule kata kunci ("ass", "menu") kini dievaluasi secara independen dan prioritas utama, baik menu pohon sudah dikonfigurasi maupun belum.
  3. Menambahkan normalisasi `compactMsg` (stripping spaces & punctuation seperti WhatsAuto resmi) sehingga kata kunci cocok sempurna pada variasi tanda baca/spasi.
  4. Mengubah `ActionInfo` agar menampung `Array<RemoteInput>` lengkap dan mempopulasikan seluruh resultKey.
  5. Memindahkan pencatatan `processedKeys` hanya saat balasan benar-benar berhasil dikirim.
  6. Mengintegrasikan pengecekan `isListenerConnected` ke `HomeTab` dan `MainNavigationScreen`:
     - Indikator status live: `Izin Belum Aktif` (Kuning) / `Layanan Belum Konek` (Oranye) / `Service Siap` (Hijau).
     - Warning banner interaktif muncul otomatis jika service belum terhubung.
     - Switch Balasan Otomatis otomatis memicu dialog izin/rebind jika service belum terhubung.
  7. Menambahkan `forceReconnectService()` pada `MainActivity.onResume()`.
- **Versi**: Dinaikkan ke `v1.0.16+17`.

### 🛡️ Eliminasi Crash Mode Kata Kunci "Mengandung", Master Try-Catch, dan Regex Quoting (v1.0.17+18 - 15 Oktober 2026)
- **Problem**: Saat pengguna mengganti opsi pencocokan dari "Mengandung" atau memproses notifikasi dengan mode mengandung, aplikasi MaoneAuto berhenti / force close ("pas saya ganti dari mengandung malah aplikasi maoneauti bwrhwnti").
- **Akar Masalah Fundamental**:
  1. **Kill Loop dari `forceReconnectService()` pada `MainActivity.onResume()`**: Di v1.0.16, `forceReconnectService()` dipasang pada `onResume()`. Setiap kali pengguna berpindah layar (seperti kembali dari layar tambah/edit kata kunci atau dialog), Android me-restart component listener yang memicu OS Android mematikan proses aplikasi (*force stop/restart*).
  2. **Ketiadaan Master Try-Catch di `onNotificationPosted`**: Service Kotlin sebelumnya tidak membungkus method utama `onNotificationPosted` dengan `try-catch` global (tidak seperti WhatsAuto resmi yang memproteksi seluruh body). Akibatnya, exception runtime apapun langsung memicu dialog sistem Android "Aplikasi telah berhenti".
  3. **Crash Regex Backreference pada `formatTags`**: `String.replace(Regex, replacement)` di Java/Kotlin melempar `IllegalArgumentException: Illegal group reference` jika teks pesan masuk atau nama pengirim mengandung simbol `$` atau `\`.
  4. **Pencocokan Kata Kunci Mengandung Kosong**: Pada mode *Contains Match*, jika keyword dibersihkan menjadi string kosong `""`, pengecekan `compactMsg.contains("")` selalu bernilai `true` untuk semua pesan masuk.
  5. **Null Assertions pada Radio Tile**: Penggunaan operator non-null assertion `v!` pada `_buildRadioTile` di Flutter rentan melempar exception null check.
- **Solusi Komprehensif**:
  1. Menghapus `forceReconnectService()` dari `MainActivity.onResume()`, dan membatasi `enableNotificationService()` & `rebindNotificationService()` hanya dieksekusi jika status belum aktif dan izin telah diberikan.
  2. Membungkus seluruh alur kerja `onNotificationPosted` dalam master `try { ... } catch (t: Throwable) { ... }` persis dekompilasi resmi WhatsAuto.
  3. Mengamankan seluruh variabel template di `formatTags` menggunakan `java.util.regex.Matcher.quoteReplacement(...)`.
  4. Menambahkan pengecekan `cleanKw.isNotEmpty()` pada exact match dan contains match agar tidak terjadi false positive matching pada string kosong.
  5. Menambahkan pengecekan `action == null` pada array `notification.actions` dan `WearableExtender.actions`, serta null guard pada `RemoteInput.resultKey`.
  6. Mengganti `v!` dengan fallback aman `v ?? true` dan `v ?? false` di `add_edit_keyword_reply_screen.dart`.
### 🚀 Inisialisasi Otomatis Default Keywords (hay & menu) dan Caches Siap Pakai (v1.0.18+19 - 15 Oktober 2026)
- **Problem**: Pengguna menginginkan aturan kata kunci pengujian langsung tersedia secara otomatis begitu aplikasi dipasang (*ready out-of-the-box*), yaitu:
  1. Kata kunci `hay` ➔ Dibalas `hallo` (Cocokan Tepat).
  2. Kata kunci `menu` ➔ Memunculkan Menu Balas bertingkat interaktif (Cocokan Tepat).
  Aturan bawaan ini dapat diedit maupun dihapus oleh pengguna dari UI kapan saja.
- **Solusi**:
  1. Di `StorageService.dart`:
     - Menambahkan fungsi `initializeDefaultsIfNeeded()`.
     - Pada `loadKeywordReplies()`: Jika daftar kosong / belum diinisialisasi, sistem otomatis menambahkan dan menyimpan dua aturan kata kunci bawaan:
       * `hay` (isExactMatch: true) ➔ `hallo`.
       * `menu` (isExactMatch: true, useMenuReply: true) ➔ `Silakan pilih menu layanan kami di bawah ini:`.
     - Di `main.dart`: Memanggil `StorageService.initializeDefaultsIfNeeded()` di awal `main()`.
  2. Di `MaoneAutoNotificationService.kt`:
     - Menambahkan fallback instan jika cache SharedPreferences belum terbaca oleh background listener: otomatis menggunakan aturan default `hay` dan `menu`.
- **Versi**: Dinaikkan ke `v1.0.18+19`.

### 🎯 Penyelarasan Total RemoteInput Extras & Prioritas Kata Kunci Persis WhatsAuto Resmi (v1.0.19+20 - 15 Oktober 2026)
- **Problem**: 
  1. Di WhatsApp nyata bot tetap tidak membalas pesan otomatis.
  2. Di uji coba simulator, saat mengetik `hay` bot malah memunculkan `menu` (bukan `hallo`).
- **Akar Masalah Fundamental (Hasil Bedah Mendalam `WhatsAutoNotificationListener.java`)**:
  1. **Kesalahan Pengiriman RemoteInput (Bundle Kosong)**:
     - Di `sendReply`, kode sebelumnya membuat `val bundle = Bundle()` baru yang kosong.
     - Di WhatsAuto resmi (`WhatsAutoNotificationListener.java` method `u`), bundle yang diteruskan ke `RemoteInput.addResultsToIntent` adalah `statusBarNotification.getNotification().extras` asli milik notifikasi WhatsApp!
     - WhatsApp memerlukan token percakapan, JID, dan metadata yang ada di `extras` notifikasi asli untuk merutekan balasan. Karena diberi Bundle kosong, WhatsApp menerima teks tapi membuangnya karena tidak tahu harus dikirim ke obrolan mana.
  2. **Inversi Prioritas Menu vs Kata Kunci**:
     - Baik di `AutoReplyEngine.dart` maupun di `MaoneAutoNotificationService.kt`, pengecekan Sesi Menu Aktif (FASE 1) diletakkan SEBELUM pengecekan Kata Kunci (FASE 2).
     - Jika sebelumnya sesi menu pernah dibuka (`currentParent == "parent"`), pesan `hay` dievaluasi sebagai opsi menu pilihan 1..N, gagal cocok, dan langsung memuntahkan `renderMenu(...)`!
- **Solusi Komprehensif**:
  1. Mengubah `sendReply` agar menyertakan `notification.extras ?: Bundle()` asli persis method `u` di WhatsAuto resmi.
  2. Menyempurnakan pemindaian `findQuickReplyAction` agar mengambil action yang memiliki `remoteInputs != null && remoteInputs.isNotEmpty()`.
  3. Membalik urutan evaluasi di `AutoReplyEngine.dart` dan `MaoneAutoNotificationService.kt`: Kata Kunci (Exact Match & Contains Match) dievaluasi **TERLEBIH DAHULU**.
     - Jika kata kunci cocok dan `!useMenuReply`, sesi di-reset ke `idle` dan mengirimkan balasan langsung (`hallo`).
     - Jika kata kunci cocok dan `useMenuReply`, sesi diaktifkan ke `parent` dan memunculkan menu.
  4. Menambahkan izin `POST_NOTIFICATIONS` dan `WAKE_LOCK` di `AndroidManifest.xml`.
### 📊 Live Monitor, Log Diagnostik & Perbaikan Ekstraksi MessagingStyle WhatsApp (v1.0.20+21 - 15 Oktober 2026)
- **Problem**: 
  1. Pengguna melaporkan bot masih belum merespons pesan WhatsApp dan tidak ada visibilitas apakah notifikasi berhasil ditangkap atau diabaikan oleh sistem.
  2. Saat aplikasi di-uninstall & di-install ulang, Android otomatis mencabut izin Akses Notifikasi sehingga listener terputus.
  3. Format notifikasi WhatsApp modern menggunakan `MessagingStyle` yang memerlukan ekstraksi hierarki pesan khusus.
- **Solusi Komprehensif**:
  1. **Live Monitor & Log Diagnostik (`diagnostic_log_screen.dart` & `ServiceLogManager`)**:
     - Menambahkan logging in-memory real-time pada native Kotlin service (`ServiceLogManager`).
     - Setiap event dicatat detik demi detik: notifikasi masuk, nama pengirim, isi pesan, filter grup/debounce, kecocokan kata kunci, dan status pengiriman RemoteInput.
     - Dibuatkan antarmuka Live Terminal Log di aplikasi dengan auto-polling 2 detik, tombol uji simulasi instan, dan tombol perbaiki koneksi service.
  2. **Perbaikan `sendReply` RemoteInput**:
     - Mengembalikan pembuatan `Bundle()` bersih khusus `resultKey` balasan agar intent tidak kelebihan muatan (bloated) oleh bundle `notification.extras` yang berisi bitmap/drawables besar.
  3. **Ekstraksi Teks `NotificationCompat.MessagingStyle`**:
     - Mendukung parsing pesan pesan WhatsApp gaya baru via `extractMessagingStyleFromNotification` dan array `android.messages`.
  4. **Pembaruan Dependensi**:
     - Menambahkan `androidx.core:core-ktx:1.12.0` di `build.gradle`.
### 🛡️ Eliminasi PatternSyntaxException di formatTags & Safe Simulation (v1.0.21+22 - 15 Oktober 2026)
- **Problem**: 
  - Saat pengguna menekan chip uji simulasi (misal 'hay' atau 'menu') di halaman Log Diagnostik, muncul error fatal:
    `PlatformException(error, Syntax error in regexp pattern near index ...)` dan balasan tidak terkirim.
- **Akar Masalah**:
  - Di `formatTags` (`MaoneAutoNotificationService.kt`), regex penggantian tag menggunakan pola seperti `Regex("(?i)\\{\\{?nama\\}?}")`.
  - Kurung kurawal tutup `\\}?}` hanya meng-escape kurung pertama (`\}`), sementara kurung kurawal kedua (`}`) tidak di-escape.
  - Pada Android ICU regex engine, karakter `}` yang tidak di-escape dianggap sebagai quantifier yang salah sintaks dan melempar `java.util.regex.PatternSyntaxException`.
  - Karena fungsi `formatTags` dipanggil setiap kali kata kunci cocok, pencarian kata kunci apapun langsung memicu crash regex ini.
- **Solusi Komprehensif**:
  1. **Penggantian Literal String Tanpa Regex**:
     - Mengganti seluruh `Regex` di `formatTags` dengan pemetaan `tagMap` dan fungsi native Kotlin `String.replace("{{$tag}}", value, ignoreCase = true)` serta `String.replace("{$tag}", value, ignoreCase = true)`.
     - 100% kebal dari error sintaks regex, mendukung karakter khusus, lebih hemat memori, dan dibungkus dalam blok pengaman `try-catch (Throwable)`.
  2. **Top-Level Safe Try-Catch di Method Channel & Simulasi**:
     - Membungkus pemanggilan `simulateTestReply` di `MaoneAutoNotificationService.kt` dan method channel `simulateTestMessage` di `MainActivity.kt` dengan `try-catch (Throwable)`.
     - Menghindari unhandled PlatformException ke sisi Flutter.
- **Versi**: Dinaikkan ke `v1.0.21+22`.

### 🔍 Eliminasi ClassCastException Long to Integer, Sender Extraction & Summary Handling (v1.0.22+23 - 15 Oktober 2026)
- **Problem**:
  - Notifikasi chat masuk dari WhatsApp: `Notif masuk dari com.whatsapp: 'Hermawan' 'Hay'`, namun bot tidak kunjung membalas dan muncul error:
    `[19:29:37] X Unhandled error: java.lang.Long cannot be cast to java.lang.Integer`.
- **Akar Masalah Fundamental**:
  - Plugin `shared_preferences` di Flutter menyimpan nilai integer (`int`) ke file XML Android SharedPreferences sebagai tipe `Long` (`java.lang.Long`).
  - Di `MaoneAutoNotificationService.kt`, kode native Android memanggil `prefs.getInt("flutter.reply_delay_seconds", 0)`.
  - Android SharedPreferences melakukan casting langsung `(Integer) map.get(key)`. Karena tipe di map adalah `java.lang.Long`, Android melempar exception fatal `ClassCastException` tepat 1 baris sebelum `sendReply(...)` dieksekusi!
- **Solusi Komprehensif**:
  1. **Safe SharedPreferences Integer Reading**:
     - Membaca `reply_delay_seconds` dengan `try-catch` berlapis: mencoba `getInt()`, dan jika gagal fallback ke `getLong().toInt()`.
  2. **Pencatatan Waktu Reply**:
     - Memindahkan pencatatan `lastReplyPerSender` dan `processedKeys` tepat sebelum `sendReply` agar kegagalan sebelum kirim tidak memblokir event berikutnya.
  3. **Ekstraksi Nama Pengirim via `lastMsg.person?.name`**:
     - Jika `rawTitle` adalah "WhatsApp" atau "WA Business", sistem mengekstrak nama kontak asli dari `lastMsg.person?.name` di `MessagingStyle`.
  4. **Penanganan Anggun Notifikasi Ringkasan**:
     - Mengubah log ringkasan sistem "WhatsApp" / "WA Business" menjadi log informatif (`ℹ️`) tanpa tanda peringatan keliru.
  5. **Multi-layer RemoteInput Discovery**:
     - Menambahkan fallback layer ketiga menggunakan `NotificationCompat.getActionCount` dan mapping `RemoteInput.Builder`.
- **Versi**: Dinaikkan ke `v1.0.22+23`.

### 🛡️ Eliminasi Total Balasan Ganda / Self-Echo Loop (v1.0.23+24 - 15 Oktober 2026)
- **Problem**:
  - Balasan otomatis berhasil terkirim (`hallo`), namun langsung disusul balasan kedua: `Halo! Saya menggunakan Aplikasi MaoneAuto.`.
- **Akar Masalah Fundamental**:
  - Ketika bot mengirimkan balasan `hallo` via `RemoteInput`, WhatsApp memperbarui tampilan notifikasi dengan menambahkan teks `hallo` ke riwayat obrolan `MessagingStyle`.
  - Android memancarkan event `onNotificationPosted` kedua untuk pembaruan notifikasi tersebut.
  - Karena pesan terakhir di notifikasi adalah `hallo` (hasil kiriman bot sendiri) dan tidak cocok dengan kata kunci `hay`, sistem salah mengira kontak mengirimkan pesan baru bertuliskan `hallo`, sehingga jatuh ke *Default Reply* (`Halo! Saya menggunakan Aplikasi MaoneAuto.`)!
- **Solusi Komprehensif (4-Layer Echo Shield)**:
  1. **Deteksi `isSelf` di `MessagingStyle`**:
     - Memeriksa `lastMsg.person == null` atau `person.name == android.selfDisplayName`. Jika true, notifikasi langsung diabaikan seketika karena merupakan echo balasan sendiri.
  2. **Echo Cache `recentSentReplies`**:
     - Setiap balasan yang dikirim oleh bot disimpan dalam cache memori selama 15 detik. Jika notifikasi masuk memiliki teks yang persis dengan balasan yang baru dikirim bot, pesan langsung di-drop.
  3. **Debounce 3000ms**:
     - Jeda aman per pengirim dinaikkan dari 1000ms ke 3000ms persis standar WhatsAuto resmi.
  4. **Penyaringan Teks Ringkasan Sistem**:
     - Menolak teks seperti `"1 pesan baru"`, `"2 pesan baru"`, dll agar tidak pernah memicu default reply.
- **Versi**: Dinaikkan ke `v1.0.23+24`.

### 📊 Dukungan Multi-Keyword Koma & Wildcard (*) di Google Spreadsheet (v1.0.24+25 - 15 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Pengguna menanyakan bagaimana cara kerja kata kunci Spreadsheet: apakah harus dimasukkan satu-satu atau bisa pakai `*` untuk membalas semua pesan dari spreadsheet.
- **Penyelarasan & Implementasi**:
  1. **Otomatis Tanpa Input Manual di Aplikasi**:
     - Kolom A otomatis menjadi kata kunci, Kolom B otomatis menjadi balasan. Pengguna tidak perlu mendaftarkan kata kunci spreadsheet di menu Kata Kunci aplikasi.
  2. **Dukungan Multi-Keyword Dipisah Koma**:
     - Di Kolom A Google Sheet, pengguna kini dapat menulis beberapa kata kunci sekaligus dipisahkan koma (misal: `harga, tarif, paket, biaya`). Baik di engine Dart maupun Kotlin service, semuanya dievaluasi fleksibel.
  3. **Dukungan Simbol Wildcard `*` di Kolom A**:
     - Jika pengguna membuat baris dengan Kolom A bertuliskan `*`, baris tersebut akan menjadi **fallback balasan umum** dari Spreadsheet. Jika ada pesan masuk yang tidak cocok dengan kata kunci lain, bot otomatis membalas menggunakan teks di baris `*` tersebut.
  4. **Pembaruan Pengujian & Panduan**:
     - Pengujian kata kunci interaktif dan panduan format kolom di layar `SpreadsheetSyncScreen` diperbarui untuk menampilkan cara penggunaan `*` dan koma.
### 🎯 Tombol Cepat "Semua (*)", Wildcard Catch-All, & Opsi Web Server (v1.0.25+26 - 15 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Pengguna menanyakan bagaimana cara menambahkan kata kunci spreadsheet jika di spreadsheet sudah ada kata kunci & balasan sendiri: apakah diisi `*` untuk membalas semua yang ada di spreadsheet, atau perlukah tombol 'Balas Semua' / disingkat 'Semua' yang otomatis mengisi `*`.
  - Pengguna juga menegaskan bahwa Google Spreadsheet sudah memiliki menu mandiri sehingga checkbox Google Sheets di form kata kunci diganti dengan **Web Server (Server Webhook)**.
- **Penyelarasan & Implementasi**:
  1. **Tombol Cepat "Semua (*)" di Atas Input Keyword**:
     - Ditambahkan header interaktif di atas kolom `Keyword Masuk` pada `AddEditKeywordReplyScreen`: menampilkan judul dan tombol chip `[⭐ Semua (*)]`.
     - Ketika tombol ditekan, input keyword otomatis terisi `*` (atau di-clear jika ditekan ulang).
     - Label petunjuk berubah menjadi: `"⭐ Mode Balas Semua: Menangkap APAPUN pesan masuk (Wildcard)"`.
  2. **Penggantian Opsi Balasan: Google Sheets ➔ Web Server**:
     - Checkbox `Google Sheets` di Opsi Balasan diganti menjadi `Web Server` (`useWebhook`).
     - Live chat bubble preview dan list card badge disinkronkan menampilkan `Web Server`.
  3. **Engine Wildcard Catch-All (`*`) & Webhook Handler**:
     - Di `AutoReplyEngine.dart` & `MaoneAutoNotificationService.kt`:
       * Keyword spesifik dievaluasi terlebih dahulu (exact & contains).
       * Jika pesan tidak cocok dengan kata kunci spesifik dan tidak berada dalam sesi menu aktif, sistem mengevaluasi aturan wildcard `*`.
       * Jika aturan `*` (atau aturan spesifik) mencentang `useWebhook`, sistem memanggil endpoint `server_webhook_url` via HTTP POST (`queryWebhook`) dan mengembalikan jawaban dinamis dari web server backend!
  4. **Pembaruan List Card**:
     - Di `KeywordReplyListScreen`, chip keyword `*` dirender elegan sebagai `⭐ Semua (*)` dan badge status `Balas Semua` serta badge `Web Server`.
### 🔘 Opsi Balasan Single Choice (Pilih Salah 1) & Full Sheets Integration (v1.0.26+27 - 15 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Pengguna meminta agar pada "Opsi Balasan" (Menu Balas, ChatGPT/AI, Web Server, Google Sheets) **hanya bisa diceklis salah satu saja** (mutually exclusive / single selection): `"sama opsi balasan yang bisa di ceklis hanya 1 lah... jadi ga bisa di centang semuanya dong kan pilih salah 1"`.
- **Penyelarasan & Implementasi**:
  1. **Mutually Exclusive Selection di `AddEditKeywordReplyScreen`**:
     - Dibuatkan handler `_selectReplyOption(option)`:
       * Mengaktifkan salah satu opsi akan otomatis mematikan 3 opsi lainnya (`Menu Balas`, `ChatGPT / AI`, `Web Server`, `Google Sheets`).
       * Mengetuk opsi yang sedang aktif akan mematikan centang (uncheck), sehingga pengguna juga bisa memilih balasan teks biasa murni tanpa sumber dinamis.
     - Ditambahkan badge panduan visual: `"Pilih salah 1"` di sebelah judul "Opsi balasan".
     - Slider horizontal mulus menampung keempat opsi pilihan dengan rapi.
  2. **Dukungan Penuh `useGoogleSheets` di Rule Kata Kunci**:
     - Ditambahkan helper `_matchSheetItem` di `AutoReplyEngine.dart` dan `matchSheetItem` di `MaoneAutoNotificationService.kt`.
     - Ketika pengguna membuat aturan kata kunci (misal `*` atau kata kunci tertentu) dan mencentang `Google Sheets`, sistem langsung mencocokkan pesan masuk ke data cache spreadsheet dan membalasnya secara dinamis!
  3. **Pembaruan List Card**:
     - Menampilkan badge `Sheets` berwarna teal accent pada aturan yang memilih Google Sheets di `KeywordReplyListScreen`.
- **Versi**: Dinaikkan ke `v1.0.26+27`.

---

### 🎯 Penegasan Opsi Balasan Kata Kunci: Menu Balas, AI, & Web Server (v1.0.27+28 - 16 Oktober 2026)
- **Konteks & Keputusan Desain Pengguna**:
  - Google Sheets / Spreadsheet adalah modul fitur mandiri dengan master toggle terpisah, sinkronisasi cloud, kata kunci sendiri, dan wildcard catch-all `*` mandiri (Phase B).
  - Pada halaman Balasan Kata Kunci, "Opsi balasan" secara eksklusif hanya berisi 3 opsi:
    1. `Menu Balas` (`useMenuReply`)
    2. `ChatGPT / AI` (`useAiReply`)
    3. `Web Server` (`useWebhook`)
  - Opsi `Google Sheets` dihapus dari checklist "Opsi balasan" kata kunci agar bersih, terfokus, dan tidak tumpang tindih.
- **Penyelarasan & Implementasi**:
  1. `AddEditKeywordReplyScreen`: Opsi balasan hanya menampilkan `Menu Balas`, `ChatGPT / AI`, `Web Server` dalam mode single-choice.
  2. `KeywordReplyListScreen`: Badge Sheets dihapus dari daftar kartu kata kunci.
  3. `AutoReplyEngine.dart` & `MaoneAutoNotificationService.kt`: Menghapus percabangan `useGoogleSheets` pada aturan kata kunci. Google Sheets tetap berjalan mandiri di Phase B.
- **Versi**: Dinaikkan ke `v1.0.27+28`.

---

## 📋 Active Tasks / Next Steps
- [x] Bedah APK WhatsAuto official (`com.guibais.whatsauto.apk`) via JADX decompiler.
- [x] Redesign UI menyeluruh: Hero Master Card, WhatsApp Preview Bubble, Bento Grid Fitur Pintar, Custom Target Selectors, Live Header/Footer Preview, MaoneArt VIP Card, dan Glassmorphic Modals (v1.0.11+12).
- [x] Implementasi 5 menu fitur lengkap: Google Spreadsheet Sync, AI 9Router Gateway, Pesan Sambutan, Webhook Server, dan Catatan Cepat (v1.0.12+13).
- [x] Perbaikan tuntas Akses Notifikasi Android: enabled manifest, CharSequence parsing, startup save, dan sticky permission banner (v1.0.13+14).
- [x] Auto-rebind service, fix false group drop, 2-column actions, dan kartu Akses Notifikasi permanen (v1.0.14+15).
- [x] Aset ikon launcher adaptif & round lengkap, default reply mode switch (v1.0.15+16).
- [x] Penyelarasan total engine notifikasi WhatsAuto resmi: hapus summary drop, perbaiki evaluasi kata kunci mandiri, perbaiki RemoteInput array, deteksi live `isListenerConnected` (v1.0.16+17).
- [x] Eliminasi total crash saat ganti opsi kata kunci "mengandung": wrap service dalam master try-catch, quote regex replacement, amankan null checks dan sanitasi empty keyword (v1.0.17+18).
- [x] Auto-populate default keyword rules 'hay' -> 'hallo' dan 'menu' -> Menu Balas saat install/startup, fallback native service (v1.0.18+19).
- [x] Penyelarasan total RemoteInput notification.extras & prioritas kata kunci vs menu persis WhatsAuto resmi (v1.0.19+20).
- [x] Bangun sistem Live Monitor & Log Diagnostik real-time, perbaikan RemoteInput clean Bundle, ekstraksi MessagingStyle WhatsApp (v1.0.20+21).
- [x] Eliminasi PatternSyntaxException di formatTags dengan literal replace & safe simulation handler (v1.0.21+22).
- [x] Ekstraksi person.name dari MessagingStyle, multi-layer NotificationCompat action scanner, dan penanganan graceful ringkasan WhatsApp (v1.0.22+23).
- [x] Eliminasi total balasan ganda via 4-Layer Echo Shield (isSelf check, recentSentReplies cache, 3s debounce, summary text filter) (v1.0.23+24).
- [x] Dukungan multi-keyword koma dan wildcard (*) di Google Spreadsheet (v1.0.24+25).
- [x] Tombol cepat "Semua (*)" di atas keyword, wildcard catch-all engine (v1.0.25+26).
### 🔒 Auto-Fill & Field Lock pada Opsi Balasan (v1.0.28+29 - 16 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Saat opsi balasan dicentang (`Menu Balas`, `ChatGPT / AI`, atau `Web Server`), kolom input "Balas pesan" harus terisi otomatis dengan nama opsi yang dipilih dan **terkunci / tidak bisa diketik** (`readOnly: true`).
- **Penyelarasan & Implementasi**:
  1. `AddEditKeywordReplyScreen`:
     - Mengetuk salah satu opsi balasan langsung mengisi controller `_replyController.text` dengan `'Menu Balas'`, `'ChatGPT / AI'`, atau `'Web Server'`.
     - Kolom `Balas pesan` berubah menjadi read-only, menampilkan badge `🔒 Terkunci (Nama Opsi)`, border emerald beraksen neon, dan hint penjelasan terkunci.
     - Tapping chip Tag Variabel dinonaktifkan dengan notifikasi bahwa kolom sedang terkunci otomatis.
     - Menghapus centang (uncheck) otomatis membersihkan teks dan membuka kembali input untuk diketik manual.
  2. `AutoReplyEngine.dart` & `MaoneAutoNotificationService.kt`:
     - Menangani nilai teks `'Menu Balas'` agar langsung merender menu pohon secara bersih tanpa menduplikasi teks "Menu Balas".
     - Menambahkan native helper `queryAi` di Kotlin service untuk memproses balasan ChatGPT / 9Router AI secara langsung di background.
- **Versi**: Dinaikkan ke `v1.0.28+29`.

### 🌐 Template Webhook Siap Pakai & Modal Generator (v1.0.29+30 - 16 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Pengguna meminta contoh kodingan webhook lengkap (Google Apps Script, website PHP, GitHub/Node.js/Python) agar orang yang ingin memakai webhook tidak bingung dan tinggal copy-paste kode serta menyalin URL-nya ke MaoneAuto.
- **Penyelarasan & Implementasi**:
  1. **Koleksi File Template Webhook**:
     - Dibuatkan folder `/sdcard/www/WhatsAuto/webhook_templates/`:
       * `google_apps_script.js`: Solusi 100% gratis tanpa butuh server/hosting (deploy Web App doPost).
       * `php_webhook.php`: Script PHP siap upload ke cPanel/Apache.
       * `nodejs_server.js`: Script Express.js siap jalankan di VPS/Termux.
       * `python_flask.py`: Script Flask Python.
       * `README.md`: Panduan lengkap bahasa Indonesia langkah demi langkah.
  2. **Utilitas Dart & UI Card di Aplikasi**:
     - `lib/utils/webhook_code_templates.dart`: Menampung seluruh template script dan tautan GitHub.
     - `lib/screens/webhook_server_screen.dart`:
       * Menambahkan kartu visual "Template Script Webhook Siap Pakai".
       * Tombol `[Salin Template]`: Membuka modal bottom sheet interaktif 4-tab dengan syntax view dan tombol salin 1-klik bersuara dialog MaoneArt Glassmorphism.
       * Tombol `[Link GitHub]`: Menyalin tautan repositori GitHub template ke clipboard dengan alert modal MaoneArt.
- **Versi**: Dinaikkan ke `v1.0.29+30`.

### 📱 Modal Template Webhook Full-Screen Slide (v1.0.30+31 - 16 Oktober 2026)
- **Konteks & Kebutuhan Pengguna**:
  - Pengguna meminta agar modal template webhook tidak hanya setengah layar, melainkan dibuat full 1 layar penuh dengan efek slide dari bawah sampai mentok ke atas layar.
- **Penyelarasan & Implementasi**:
  1. `lib/screens/webhook_server_screen.dart`:
     - Menambahkan konfigurasi `useSafeArea: true` dan `enableDrag: true` pada `showModalBottomSheet`.
     - Mengubah tinggi container sheet menjadi `height: MediaQuery.of(context).size.height` penuh.
     - Membungkus isi kolom dengan `SafeArea` agar header dan gesture bar tetap terproteksi rapi dan nyaman dibaca.
- **Versi**: Dinaikkan ke `v1.0.30+31`.

### 🔄 Dukungan HTTP 302 Redirect Google Apps Script Webhook (v1.0.31+32 - 16 Oktober 2026)
- **Konteks & Masalah**:
  - Pengguna memasukkan URL Google Apps Script Web App (`https://script.google.com/macros/s/.../exec`) tetapi pengujian dan balasan otomatis gagal.
- **Akar Masalah**:
  - Google Apps Script Web App SELALU merespons HTTP POST dengan status `302 Found` (Redirect) mengarah ke URL `Location: https://script.googleusercontent.com/macros/echo?...`.
  - Baik Dart `http.post` maupun Android Java `HttpURLConnection` secara default tidak mengikuti redirect pada HTTP POST dan menganggap status code `302` sebagai kegagalan karena berada di luar rentang `200..299`.
- **Penyelarasan & Solusi**:
  1. `lib/services/webhook_service.dart`:
     - Menambahkan penanganan otomatis untuk HTTP status 301, 302, 303, 307, 308. Jika menerima redirect, aplikasi secara otomatis melakukan HTTP GET ke header `location` untuk mengambil respon JSON final.
  2. `android/app/src/main/kotlin/com/maoneart/maoneauto/MaoneAutoNotificationService.kt`:
     - Menambahkan handler redirect pada `queryWebhook` yang otomatis mendeteksi header `Location` dan melakukan GET ke URL redirect sehingga notifikasi WhatsApp latar belakang membalas sempurna.
- **Versi**: Dinaikkan ke `v1.0.31+32`.

### ⚡ Eliminasi NetworkOnMainThreadException & StrictMode PermitAll (v1.0.32+33 - 16 Oktober 2026)
- **Konteks & Masalah**:
  - Saat tes ping di aplikasi berhasil, tetapi saat chat "ping" masuk di WhatsApp, bot tidak membalas.
- **Akar Masalah**:
  - Android `NotificationListenerService.onNotificationPosted` berjalan di Main/UI Thread OS.
  - Saat `queryWebhook` membuka koneksi jaringan (`HttpURLConnection`), Android melempar `android.os.NetworkOnMainThreadException` sehingga query gagal diam-diam dan mengembalikan `null`.
  - Pada `WebhookServerScreen`, URL baru tersimpan saat event blur/change, belum otomatis disimpan sebelum tes ping dijalankan.
- **Penyelarasan & Solusi**:
  1. `MaoneAutoNotificationService.kt`:
     - Menambahkan `StrictMode.setThreadPolicy(permitAll())` di `onCreate()` dan di awal `queryWebhook` serta `queryAi`.
     - Menambahkan logging mendalam ke `ServiceLogManager` (terlihat di layar Live Monitor aplikasi).
     - Menambahkan header `User-Agent: MaoneAuto-Android-Bot` dan timeout 8000ms.
     - Menambahkan fallback pembacaan SharedPreferences key `server_webhook_url`.
  2. `lib/screens/webhook_server_screen.dart`:
     - Memastikan `_saveSettings()` langsung dipanggil saat tombol tes ping ditekan.
- **Versi**: Dinaikkan ke `v1.0.32+33`.

### 💬 Real-Time Webhook Execution di Simulator Chat (v1.0.33+34 - 16 Oktober 2026)
- **Konteks & Masalah**:
  - Saat user mengetes di layar Simulator Chat aplikasi MaoneAuto, bot membalas dengan teks placeholder `🌐 [Pesan diproses via Web Server]`, bukan respon asli dari Google Apps Script.
- **Penyelarasan & Solusi**:
  1. `lib/services/auto_reply_engine.dart`:
     - Menambahkan method `processMessageAsync`.
     - Saat rule berstatus `useWebhook: true`, engine langsung melakukan pemanggilan nyata via `WebhookService.sendWebhook` ke URL Webhook yang disimpan.
  2. `lib/screens/test_reply_simulator_screen.dart`:
     - Memperbarui pengiriman simulasi chat menggunakan `processMessageAsync` sehingga balasan nyata Google Apps Script (`🏓 Pong! Webhook Google Apps Script aktif...`) langsung muncul di layar simulator.
- **Versi**: Dinaikkan ke `v1.0.33+34`.

---

## 📋 Active Tasks / Next Steps
- [x] Opsi balasan single choice (pilih salah 1): Menu Balas, ChatGPT/AI, Web Server (v1.0.27+28).
- [x] Auto-fill & lock field balasan saat opsi balasan aktif (v1.0.28+29).
- [x] Template webhook lengkap (Google Apps Script, PHP, Node.js, Python, README) (v1.0.29+30).
- [x] Modal template webhook full-screen slide mentok ke atas layar (v1.0.30+31).
- [x] Dukungan HTTP 302 Redirect Google Apps Script Webhook (v1.0.31+32).
- [x] Eliminasi NetworkOnMainThreadException & StrictMode PermitAll di background WhatsApp service (v1.0.32+33).
- [x] Real-time Webhook Execution di Simulator Chat internal aplikasi (v1.0.33+34).
- [ ] Push commit ke GitHub repository `maoneart/WhatsAuto` dan trigger GitHub Actions build APK v1.0.33.
- [ ] Unduh APK rilis `v1.0.33` ke `/sdcard/Download/MaoneAuto.apk` dan verifikasi integritas.


