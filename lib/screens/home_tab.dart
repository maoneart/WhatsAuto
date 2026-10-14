import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';
import 'menu_reply_screen.dart';
import 'test_reply_simulator_screen.dart';

class HomeTab extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;

  const HomeTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  void _toggleAutoReply(bool val) async {
    setState(() {
      widget.settings.isAutoReplyEnabled = val;
    });
    await StorageService.saveSettings(widget.settings);
    widget.onSettingsChanged();
  }

  void _editDefaultReply() {
    final controller = TextEditingController(text: widget.settings.defaultReply);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Balasan Default', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tulis balasan default...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFF111B21),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          widget.settings.defaultReply = controller.text.trim();
                        });
                        await StorageService.saveSettings(widget.settings);
                        widget.onSettingsChanged();
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.settings.isAutoReplyEnabled;

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
            tooltip: 'Tanggapan Uji / Simulator',
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.white70),
            onPressed: () {
              GlassmorphismModal.showAlertModal(
                context: context,
                title: 'WhatsApp Gateway Bot',
                message: 'Bot WhatsApp lokal siap menerima dan membalas pesan secara otomatis.',
              );
            },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch Master Card: Balasan otomatis HIDUP / MATI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEnabled ? 'Balasan otomatis HIDUP' : 'Balasan otomatis MATI',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Switch(
                    value: isEnabled,
                    onChanged: _toggleAutoReply,
                    activeColor: const Color(0xFF00A884),
                    activeTrackColor: const Color(0xFF00A884).withOpacity(0.5),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Card Balasan Default
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balasan default',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF00A884),
                        ),
                      ),
                      InkWell(
                        onTap: _editDefaultReply,
                        child: const Icon(Icons.edit, size: 18, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.settings.defaultReply,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Section: Buat balasan otomatis
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Buat balasan otomatis',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00A884),
                          ),
                        ),
                        Icon(Icons.fullscreen, color: Colors.white.withOpacity(0.5)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'balasan tersimpan.',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),

                  // 1. Balasan AI
                  _buildActionTile(
                    icon: Icons.chat_outlined,
                    iconColor: const Color(0xFF00A884),
                    title: 'Balasan AI',
                    subtitle: 'Biarkan AI menjawab pertanyaan pelanggan dari informasi bisnis Anda atau situs web Anda.',
                    onTap: () {
                      GlassmorphismModal.showAlertModal(
                        context: context,
                        title: 'Balasan AI Terintegrasi',
                        message: 'Fitur Balasan AI otomatis terhubung dengan 9Router Gateway port 20128 & Gemini API.',
                      );
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),

                  // 2. Menu Balas (Pohon Menu WhatsAuto)
                  _buildActionTile(
                    icon: Icons.forum_outlined,
                    iconColor: const Color(0xFF00A884),
                    title: 'Menu Balas',
                    subtitle: 'Kirim opsi agar pelanggan dapat memilih apa yang mereka butuhkan.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MenuReplyScreen()),
                      );
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.08), height: 1),

                  // 3. Google Sheets
                  _buildActionTile(
                    icon: Icons.table_chart_outlined,
                    iconColor: const Color(0xFF00A884),
                    title: 'Google Sheets',
                    subtitle: 'Gunakan data Google Sheets untuk menjawab pertanyaan pelanggan.',
                    onTap: () {
                      GlassmorphismModal.showAlertModal(
                        context: context,
                        title: 'Integrasi Google Sheets',
                        message: 'Sinkronkan data spreadsheet Anda secara langsung untuk balasan otomatis.',
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
