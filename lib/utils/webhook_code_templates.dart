class WebhookCodeTemplates {
  static const String githubTemplatesUrl = 'https://github.com/maoneart/WhatsAuto/tree/main/webhook_templates';

  static const String gasTemplate = '''/**
 * =========================================================================
 * WEBHOOK MAONEAUTO - GOOGLE APPS SCRIPT (GAS)
 * =========================================================================
 * Gratis 100% tanpa perlu sewa VPS / Web Hosting!
 * 
 * CARA PAKAI:
 * 1. Buka https://script.google.com -> Klik "New project"
 * 2. Hapus semua kode bawaan, lalu paste seluruh script ini
 * 3. Klik "Deploy" -> "New deployment"
 * 4. Pilih tipe "Web app"
 * 5. Konfigurasi:
 *    - Execute as : Me (Email Anda)
 *    - Who has access : Anyone (Siapa saja)  <-- WAJIB
 * 6. Klik Deploy -> Salin "Web App URL" (akhiran /exec)
 * 7. Tempelkan URL tersebut ke kolom Webhook di aplikasi MaoneAuto!
 * =========================================================================
 */

function doPost(e) {
  try {
    var postData = e.postData.contents;
    var data = JSON.parse(postData);
    
    var sender = data.sender || "Pelanggan";
    var message = (data.message || "").trim();
    var cleanMsg = message.toLowerCase();
    
    var replyText = "";
    
    // Tentukan balasan otomatis Anda di sini:
    if (cleanMsg === "ping" || cleanMsg === "tes") {
      replyText = "🏓 Pong! Webhook Google Apps Script aktif normal.";
    } 
    else if (cleanMsg.indexOf("harga") !== -1 || cleanMsg.indexOf("biaya") !== -1) {
      replyText = "Halo kak " + sender + "! Paket layanan kami mulai dari Rp 50.000,-.";
    } 
    else if (cleanMsg.indexOf("alamat") !== -1 || cleanMsg.indexOf("lokasi") !== -1) {
      replyText = "📍 Lokasi kantor kami: Jl. KH. Noer Ali No. 88, Bekasi Timur.";
    } 
    else if (cleanMsg.indexOf("admin") !== -1 || cleanMsg.indexOf("cs") !== -1) {
      replyText = "Pesan Anda telah diteruskan ke Customer Support kami. Mohon ditunggu sebentar ya.";
    } 
    else {
      // Balasan default
      replyText = "Halo kak! Terima kasih atas pesan Anda: \\"" + message + "\\". Ada yang bisa kami bantu?";
    }
    
    // Kembalikan respon format JSON { "reply": "..." }
    var responseJson = {
      "reply": replyText
    };
    
    return ContentService.createTextOutput(JSON.stringify(responseJson))
      .setMimeType(ContentService.MimeType.JSON);
      
  } catch (err) {
    var errJson = { "reply": "⚠️ Terjadi kesalahan: " + err.toString() };
    return ContentService.createTextOutput(JSON.stringify(errJson))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  return ContentService.createTextOutput(JSON.stringify({
    "status": "online",
    "service": "MaoneAuto Webhook GAS Server"
  })).setMimeType(ContentService.MimeType.JSON);
}''';

  static const String phpTemplate = '''<?php
/**
 * =========================================================================
 * WEBHOOK MAONEAUTO - PHP (WEBSITE / CPANEL / HOSTING)
 * =========================================================================
 * 
 * CARA PAKAI:
 * 1. Simpan berkas ini sebagai webhook.php di hosting cPanel / server Anda.
 * 2. URL Anda menjadi: https://domainanda.com/webhook.php
 * 3. Tempelkan URL tersebut ke kolom Webhook di aplikasi MaoneAuto!
 * =========================================================================
 */

header('Content-Type: application/json; charset=utf-8');

if (\$_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed, use POST']);
    exit;
}

\$raw = file_get_contents('php://input');
\$data = json_decode(\$raw, true);

if (!\$data) {
    echo json_encode(['reply' => 'Format payload tidak valid.']);
    exit;
}

\$sender = \$data['sender'] ?? 'Pelanggan';
\$message = trim(\$data['message'] ?? '');
\$cleanMsg = strtolower(\$message);

\$reply = '';
if (\$cleanMsg === 'ping' || \$cleanMsg === 'tes') {
    \$reply = "🏓 Pong! Webhook PHP aktif dan terhubung sempurna.";
} elseif (strpos(\$cleanMsg, 'harga') !== false) {
    \$reply = "Halo kak {\$sender}! Paket layanan kami mulai dari Rp 50.000,-.";
} elseif (strpos(\$cleanMsg, 'admin') !== false) {
    \$reply = "Pesan Anda telah diteruskan ke Customer Support kami.";
} else {
    \$reply = "Halo kak! Terima kasih atas pesan Anda: \\"{\$message}\\".";
}

echo json_encode(['reply' => \$reply], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);''';

  static const String nodejsTemplate = '''/**
 * =========================================================================
 * WEBHOOK MAONEAUTO - NODE.JS (EXPRESS)
 * =========================================================================
 * 
 * CARA PAKAI:
 * 1. npm init -y && npm install express
 * 2. Simpan sebagai server.js
 * 3. Jalankan: node server.js
 * 4. URL: http://IP_SERVER:3000/webhook
 * =========================================================================
 */

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.post('/webhook', (req, res) => {
    const { sender, message } = req.body;
    const cleanMsg = (message || '').toLowerCase().trim();

    let reply = `Halo kak! Pesan Anda: "\${message}" telah kami terima.`;

    if (cleanMsg === 'ping' || cleanMsg === 'tes') {
        reply = "🏓 Pong! Webhook Node.js aktif normal.";
    } else if (cleanMsg.includes('harga') || cleanMsg.includes('biaya')) {
        reply = "Halo! Paket layanan kami mulai dari Rp 50.000,-.";
    } else if (cleanMsg.includes('admin')) {
        reply = "Pesan Anda telah masuk ke sistem tiket antrian kami.";
    }

    res.json({ reply });
});

app.listen(PORT, () => console.log(`Webhook server berjalan di port \${PORT}`));''';

  static const String nodeTemplate = nodejsTemplate;

  static const String pythonTemplate = '''"""
=========================================================================
WEBHOOK MAONEAUTO - PYTHON (FLASK)
=========================================================================

CARA PAKAI:
1. pip install flask
2. Simpan sebagai app.py lalu jalankan: python app.py
3. URL: http://IP_SERVER:5000/webhook
=========================================================================
"""
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.get_json(force=True) or {}
    sender = data.get('sender', 'Pelanggan')
    message = data.get('message', '').strip()
    clean_msg = message.lower()

    if clean_msg in ['ping', 'tes', 'test']:
        reply = "🏓 Pong! Webhook Python Flask aktif."
    elif 'harga' in clean_msg:
        reply = f"Halo kak {sender}! Harga layanan kami mulai dari Rp 50.000,-."
    else:
        reply = f"Halo kak! Pesan '{message}' telah diterima di server."

    return jsonify({"reply": reply})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)''';
}
