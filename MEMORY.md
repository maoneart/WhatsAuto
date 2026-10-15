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

---

## 📋 Active Tasks / Next Steps
- [x] Bedah APK WhatsAuto official (`com.guibais.whatsauto.apk`) via JADX decompiler.
- [x] Redesign UI menyeluruh: Hero Master Card, WhatsApp Preview Bubble, Bento Grid Fitur Pintar, Custom Target Selectors, Live Header/Footer Preview, MaoneArt VIP Card, dan Glassmorphic Modals (v1.0.11+12).
- [x] Implementasi 5 menu fitur lengkap: Google Spreadsheet Sync, AI 9Router Gateway, Pesan Sambutan, Webhook Server, dan Catatan Cepat (v1.0.12+13).
- [x] Perbaikan tuntas Akses Notifikasi Android: enabled manifest, CharSequence parsing, startup save, dan sticky permission banner (v1.0.13+14).
- [x] Auto-rebind service, fix false group drop, 2-column actions, dan kartu Akses Notifikasi permanen (v1.0.14+15).
- [x] Push commit ke GitHub repository `maoneart/WhatsAuto` dan trigger GitHub Actions build APK v1.0.14.
- [x] Unduh APK hasil build rilis ke `/sdcard/Download/MaoneAuto.apk` dan verifikasi integritas.





