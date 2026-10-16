# 🌐 Template & Panduan Webhook Server MaoneAuto

Koleksi template siap pakai untuk menghubungkan fitur **Webhook Server** di aplikasi **MaoneAuto** ke backend Anda sendiri.

---

## ⚡ Cara Kerja Webhook MaoneAuto
Ketika ada pesan masuk di WhatsApp yang diarahkan ke Webhook Server, MaoneAuto akan mengirimkan HTTP POST request berformat JSON:

```json
{
  "sender": "+628123456789",
  "message": "halo mau tanya harga",
  "app": "WhatsApp",
  "timestamp": "2026-10-16T07:30:00"
}
```

Server Anda cukup membalas dengan HTTP 200 OK berisi JSON:
```json
{
  "reply": "Halo! Harga paket kami mulai dari Rp 50.000,-."
}
```
*(Atau teks biasa tanpa JSON juga didukung).*

---

## 📂 Pilihan Template yang Tersedia

### 1. [Google Apps Script (`google_apps_script.js`)](./google_apps_script.js) (⭐ Sangat Direkomendasikan - Gratis 100%)
- **Kelebihan**: Tanpa perlu sewa server/hosting, langsung aktif di cloud Google, terhubung ke Google Drive/Spreadsheet jika dibutuhkan.
- **Cara Deploy**:
  1. Buka [Google Apps Script](https://script.google.com).
  2. Buat proyek baru dan tempelkan kode dari [`google_apps_script.js`](./google_apps_script.js).
  3. Klik **Deploy** -> **New deployment**.
  4. Pilih type **Web app**.
  5. Konfigurasi: **Execute as: Me**, **Who has access: Anyone**.
  6. Salin **Web App URL** (yang berakhiran `/exec`) dan tempelkan ke aplikasi MaoneAuto!

---

### 2. [PHP (`php_webhook.php`)](./php_webhook.php)
- Cocok untuk pengguna website cPanel, Shared Hosting, VPS, atau Localhost Apache di Termux.
- Cukup unggah berkas `php_webhook.php` ke folder web Anda (misal `public_html/webhook.php`).
- Masukkan URL: `https://domainanda.com/webhook.php`.

---

### 3. [Node.js Express (`nodejs_server.js`)](./nodejs_server.js)
- Cocok untuk server Node.js di VPS, Railway, Render, Glitch, atau Termux.
- Jalankan dengan: `npm install express && node server.js`.

---

### 4. [Python Flask (`python_flask.py`)](./python_flask.py)
- Cocok untuk pengguna Python, AI framework, atau integrasi data science.
- Jalankan dengan: `pip install flask && python python_flask.py`.
