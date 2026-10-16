import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = 'v1.0.34';
  static const String developerName = 'Hermawan (MaoneArt)';
  static const String languageFramework = 'Flutter (Dart) & Native Android (Kotlin)';

  void _openNotificationSettings() {
    try {
      const MethodChannel('com.maoneart.maoneauto/service')
          .invokeMethod('openNotificationSettings');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Tutup',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            // 1. Logo & App Identity Hero
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A884), Color(0xFF128C7E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00A884).withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_chat_read_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'MaoneAuto',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Smart WhatsApp Auto-Reply & Tree Menu Bot',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF00A884).withOpacity(0.4),
                      ),
                    ),
                    child: const Text(
                      '$appVersion • Official Release',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A884),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Info Detail Spesifikasi Aplikasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.developer_mode_rounded, color: Color(0xFF00A884), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Informasi Pengembangan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildInfoRow('Pembuat', developerName, icon: Icons.person_outline),
                  const SizedBox(height: 12),
                  _buildInfoRow('Versi Aplikasi', appVersion, icon: Icons.tag),
                  const SizedBox(height: 12),
                  _buildInfoRow('Bahasa & Engine', languageFramework, icon: Icons.code_rounded),
                  const SizedBox(height: 12),
                  _buildInfoRow('Sistem UI', 'MaoneArt Glassmorphism Dark', icon: Icons.palette_outlined),
                  const SizedBox(height: 12),
                  _buildInfoRow('Target OS', 'Android 8.0 s/d Android 15+', icon: Icons.android_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Card Fitur & Arsitektur Utama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF38BDF8), size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Fitur Unggulan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  _buildFeatureBullet(
                    '⚡ Background Reply Service',
                    'Merespons otomatis langsung dari bar notifikasi Android via RemoteInput tanpa membuka layar.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    '🌲 Interactive Tree Menu Bot',
                    'Katalog pohon bertingkat dengan navigasi angka, tombol kembali, dan ekspor/impor CSV.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    '🤖 Multi-Provider AI Assistant',
                    'Dukungan 9Router AI Gateway lokal, OpenAI-compatible API, dan Google Gemini Cloud.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    '🌐 Webhook Server Integration',
                    'Terhubung ke Google Apps Script (HTTP 302 redirect), PHP, Node.js Express, dan Flask Python.',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureBullet(
                    '📊 Google Sheets Online',
                    'Sinkronisasi kata kunci dan balasan dinamis langsung dari tabel Google Spreadsheet.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Tombol Aksi 100% Simetris 2-Kolom Grid
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: const Color(0xFF00A884).withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _openNotificationSettings,
                      icon: const Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFF00A884)),
                      label: const Text(
                        'Akses Notifikasi',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Tutup Halaman',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Footer Copyright
            Text(
              '© 2026 MaoneArt. Dibuat dengan bangga oleh Hermawan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {required IconData icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.white38),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12.5,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: Colors.white38)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFE9EDEF),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
