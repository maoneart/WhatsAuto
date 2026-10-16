/**
 * =========================================================================
 * WEBHOOK SERVER MAONEAUTO - GOOGLE APPS SCRIPT (GAS)
 * =========================================================================
 * Gratis 100% tanpa perlu sewa VPS / Web Hosting!
 * 
 * PANDUAN DEPLOY SEBAGAI WEB APP (HANYA 1 MENIT):
 * 1. Buka browser: https://script.google.com
 * 2. Klik tombol "+ Proyek Baru" (New Project).
 * 3. Hapus seluruh isi default, lalu PASTE SELURUH KODE DI BAWAH INI.
 * 4. Klik menu "Deploy" (Terapkan) di pojok kanan atas -> pilih "New deployment" (Deployment baru).
 * 5. Klik ikon gerigi (Select type) -> pilih "Web app" (Aplikasi Web).
 * 6. Konfigurasi:
 *    - Description : Webhook MaoneAuto
 *    - Execute as  : Me (Email Google Anda)
 *    - Who has access : Anyone (Siapa saja)  <-- WAJIB PILIH "ANYONE"
 * 7. Klik "Deploy" -> Izinkan akses (Authorize Access) jika diminta.
 * 8. SALIN "Web App URL" (URL yang berakhiran /exec).
 *    Contoh: https://script.google.com/macros/s/AKfycbx.../exec
 * 9. Tempelkan URL tersebut ke kolom "URL Webhook Server" di aplikasi MaoneAuto!
 * =========================================================================
 */

function doPost(e) {
  try {
    // 1. Ekstraksi payload JSON dari MaoneAuto
    var postData = e.postData.contents;
    var request = JSON.parse(postData);
    
    var sender = request.sender || "Pelanggan"; // Nomor / nama WhatsApp pengirim
    var message = (request.message || "").trim(); // Teks pesan asli
    var cleanMsg = message.toLowerCase();        // Teks huruf kecil untuk pencocokan
    
    var replyText = "";
    
    // 2. Tentukan logika balasan otomatis Anda di sini:
    if (cleanMsg === "ping" || cleanMsg === "tes" || cleanMsg === "test") {
      replyText = "🏓 Pong! Webhook Google Apps Script aktif dan terhubung normal.";
    } 
    else if (cleanMsg.indexOf("harga") !== -1 || cleanMsg.indexOf("biaya") !== -1 || cleanMsg.indexOf("tarif") !== -1) {
      replyText = "Halo kak " + sender + "! Paket layanan MaoneAuto mulai dari Rp 50.000,-. Kunjungi website kami untuk info lengkap.";
    } 
    else if (cleanMsg.indexOf("alamat") !== -1 || cleanMsg.indexOf("lokasi") !== -1) {
      replyText = "📍 Lokasi kantor kami: Jl. KH. Noer Ali No. 88, Bekasi Timur. Buka Senin-Sabtu jam 08:00 - 17:00 WIB.";
    } 
    else if (cleanMsg.indexOf("admin") !== -1 || cleanMsg.indexOf("cs") !== -1 || cleanMsg.indexOf("bantuan") !== -1) {
      replyText = "Halo kak! Pesan Anda telah diteruskan ke Customer Support kami. Mohon ditunggu sebentar ya.";
    } 
    else {
      // Balasan umum / default jika tidak ada kata kunci yang cocok
      replyText = "Halo kak! Terima kasih telah menghubungi kami. Pesan Anda: \"" + message + "\" telah kami terima di server.";
    }
    
    // 3. Kembalikan respon format JSON { "reply": "..." }
    var responseJson = {
      "reply": replyText
    };
    
    return ContentService.createTextOutput(JSON.stringify(responseJson))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (error) {
    // Tangani jika terjadi error
    var errResponse = {
      "reply": "⚠️ Maaf, terjadi kesalahan di server Webhook: " + error.toString()
    };
    return ContentService.createTextOutput(JSON.stringify(errResponse))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

// Handler GET untuk pengujian langsung via browser
function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    "status": "online",
    "service": "MaoneAuto Webhook GAS Server",
    "message": "Webhook siap menerima request POST dari aplikasi MaoneAuto!"
  })).setMimeType(ContentService.MimeType.JSON);
}
