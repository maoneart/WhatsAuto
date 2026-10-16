/**
 * =========================================================================
 * WEBHOOK SERVER MAONEAUTO - NODE.JS (EXPRESS)
 * =========================================================================
 * 
 * PANDUAN PENGGUNAAN:
 * 1. Jalankan di terminal:
 *    npm init -y
 *    npm install express
 * 2. Simpan file ini sebagai server.js
 * 3. Jalankan: node server.js
 * 4. URL webhook Anda: http://IP_SERVER:3000/webhook (atau domain via reverse proxy / tunnel)
 * =========================================================================
 */

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.post('/webhook', (req, res) => {
    const { sender, message, app: clientApp, timestamp } = req.body;
    console.log(`[MaoneAuto] Pesan dari ${sender}: "${message}"`);

    const cleanMsg = (message || '').toLowerCase().trim();
    let reply = `Halo kak! Pesan Anda: "${message}" telah diterima oleh server bot kami.`;

    if (cleanMsg === 'ping' || cleanMsg === 'tes' || cleanMsg === 'test') {
        reply = "🏓 Pong! Webhook Node.js aktif dan berjalan normal.";
    } else if (cleanMsg.includes('harga') || cleanMsg.includes('biaya')) {
        reply = "Halo! Paket layanan kami mulai dari Rp 50.000,-.";
    } else if (cleanMsg.includes('admin') || cleanMsg.includes('cs')) {
        reply = "Pesan Anda sudah masuk ke sistem tiket kami. Admin akan segera menghubungi Anda.";
    }

    // Kembalikan JSON { "reply": "..." }
    res.json({ reply });
});

app.get('/webhook', (req, res) => {
    res.json({ status: "online", service: "MaoneAuto Node.js Webhook Server" });
});

app.listen(PORT, () => {
    console.log(`🚀 Webhook server MaoneAuto berjalan di port ${PORT}`);
});
