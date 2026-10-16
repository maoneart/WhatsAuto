<?php
/**
 * =========================================================================
 * WEBHOOK SERVER MAONEAUTO - PHP (WEBSITE / CPANEL / HOSTING / APACHE)
 * =========================================================================
 * 
 * PANDUAN PENGGUNAAN:
 * 1. Simpan berkas ini di public directory hosting Anda (contoh: public_html/webhook.php).
 * 2. URL webhook Anda akan menjadi: https://domainanda.com/webhook.php
 * 3. Salin URL tersebut dan masukkan ke dalam aplikasi MaoneAuto!
 * =========================================================================
 */

header('Content-Type: application/json; charset=utf-8');

// Hanya izinkan HTTP POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'status' => 'error',
        'message' => 'Hanya menerima request method POST dari MaoneAuto'
    ]);
    exit;
}

// Baca body JSON yang dikirimkan MaoneAuto
$rawInput = file_get_contents('php://input');
$data = json_decode($rawInput, true);

if (!$data) {
    echo json_encode([
        'reply' => '⚠️ Format data payload tidak valid.'
    ]);
    exit;
}

$sender = $data['sender'] ?? 'Pelanggan';
$message = trim($data['message'] ?? '');
$cleanMsg = strtolower($message);

$replyText = '';

// Tentukan balasan otomatis kustom Anda di sini:
if ($cleanMsg === 'ping' || $cleanMsg === 'tes' || $cleanMsg === 'test') {
    $replyText = "🏓 Pong! Webhook PHP aktif dan terhubung sempurna.";
} elseif (strpos($cleanMsg, 'harga') !== false || strpos($cleanMsg, 'biaya') !== false) {
    $replyText = "Halo kak {$sender}! Harga produk & layanan kami mulai dari Rp 50.000,-.";
} elseif (strpos($cleanMsg, 'alamat') !== false || strpos($cleanMsg, 'lokasi') !== false) {
    $replyText = "📍 Lokasi kantor kami di Bekasi Timur. Silakan kunjungi website kami untuk petunjuk arah.";
} elseif (strpos($cleanMsg, 'admin') !== false || strpos($cleanMsg, 'cs') !== false) {
    $replyText = "Pesan Anda telah diteruskan ke Customer Support kami. Mohon ditunggu sebentar ya.";
} else {
    // Balasan default
    $replyText = "Halo kak! Terima kasih atas pesan Anda: \"{$message}\". Ada yang bisa kami bantu?";
}

// Kembalikan balasan format JSON { "reply": "..." }
echo json_encode([
    'reply' => $replyText
], JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
