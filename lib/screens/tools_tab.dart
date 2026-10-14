import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../widgets/glassmorphism_modal.dart';
import 'menu_reply_screen.dart';
import 'test_reply_simulator_screen.dart';

class ToolsTab extends StatelessWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;

  const ToolsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'MaoneAuto',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TestReplySimulatorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.white70),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Profile User
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFF00A884),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF1F2C34),
                        child: Icon(Icons.person, color: Colors.white, size: 28),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hai, Her Mawan',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Tipe akun: Premium',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grid Menu Alat (2 Kolom)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.95,
              children: [
                // 1. Aplikasi yang Didukung
                _buildGridItem(
                  context: context,
                  icon: Icons.apps,
                  title: 'Aplikasi yang Didukung',
                  subtitle: 'Pilih aplikasi pesan untuk mengirim balasan.',
                  onTap: () {
                    _showSupportedAppsModal(context);
                  },
                ),

                // 2. Balasan Kata Kunci
                _buildGridItem(
                  context: context,
                  icon: Icons.chat_outlined,
                  title: 'Balasan Kata Kunci',
                  subtitle: 'Balasan yang dipersonalisasi berdasarkan kata kunci.',
                  onTap: () {
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Balasan Kata Kunci',
                      message: 'Atur respon spesifik ketika pelanggan mengetik kata kunci tertentu.',
                    );
                  },
                ),

                // 3. Balasan AI
                _buildGridItem(
                  context: context,
                  icon: Icons.smart_toy_outlined,
                  title: 'Balasan AI',
                  subtitle: 'Balasan yang dihasilkan AI menggunakan 9Router & Gemini.',
                  onTap: () {
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: '9Router AI Gateway',
                      message: 'Terhubung ke server AI lokal port 20128 & Google Gemini API.',
                    );
                  },
                ),

                // 4. Lembar Kerja
                _buildGridItem(
                  context: context,
                  icon: Icons.table_chart_outlined,
                  title: 'Lembar kerja',
                  subtitle: 'Hubungkan Google Sheet untuk menjawab pertanyaan pelanggan...',
                  onTap: () {
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Google Spreadsheet',
                      message: 'Integrasi spreadsheet online untuk katalog produk dan harga.',
                    );
                  },
                ),

                // 5. Menu Balas (Pohon Hierarki WhatsAuto)
                _buildGridItem(
                  context: context,
                  icon: Icons.forum_outlined,
                  title: 'Menu Balas',
                  subtitle: 'Kirim daftar opsi untuk dipilih, dengan balasan sub-menu.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MenuReplyScreen()),
                    );
                  },
                ),

                // 6. Pesan Selamat Datang
                _buildGridItem(
                  context: context,
                  icon: Icons.star_border,
                  title: 'Pesan Selamat Datang',
                  subtitle: 'Kirim pesan sambutan ketika seseorang mengirim pesan kepada...',
                  onTap: () {
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Pesan Selamat Datang',
                      message: 'Sambutan ramah otomatis untuk kontak baru yang pertama kali chat.',
                    );
                  },
                ),

                // 7. Server
                _buildGridItem(
                  context: context,
                  icon: Icons.dns_outlined,
                  title: 'Server',
                  subtitle: 'Dapatkan respon waktu nyata dari server Anda sendiri.',
                  onTap: () {
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Webhook Server',
                      message: 'Kirim payload pesan ke API lokal (port 8085 / 8088) dan terima respon dinamis.',
                    );
                  },
                ),

                // 8. Tanggapan Uji (Simulator)
                _buildGridItem(
                  context: context,
                  icon: Icons.phonelink_setup,
                  title: 'Tanggapan Uji',
                  subtitle: 'Uji pesan balasan otomatis Anda dengan alat simulasi ini.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestReplySimulatorScreen()),
                    );
                  },
                ),

                // 9. Catatan
                _buildGridItem(
                  context: context,
                  icon: Icons.note_outlined,
                  title: 'Catatan',
                  subtitle: 'Buat catatan untuk dibagikan dengan aplikasi pesan lain deng...',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportedAppsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111B21),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aplikasi yang Didukung', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAppCheck(ctx, 'WhatsApp', true),
            _buildAppCheck(ctx, 'WhatsApp Business', true),
            _buildAppCheck(ctx, 'Telegram', false),
            _buildAppCheck(ctx, 'Facebook Messenger', false),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A884),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCheck(BuildContext ctx, String name, bool defaultVal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
          Switch(
            value: defaultVal,
            onChanged: (v) {},
            activeColor: const Color(0xFF00A884),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111B21),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF00A884), size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
