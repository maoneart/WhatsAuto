import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';
import 'menu_reply_screen.dart';
import 'test_reply_simulator_screen.dart';
import 'keyword_reply_list_screen.dart';
import 'spreadsheet_sync_screen.dart';
import 'ai_reply_screen.dart';

class HomeTab extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;
  final bool isNotificationPermissionGranted;
  final VoidCallback? onRequestPermission;

  const HomeTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    this.isNotificationPermissionGranted = true,
    this.onRequestPermission,
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

  void _editDefaultReply() async {
    final result = await GlassmorphismModal.showInputModal(
      context: context,
      title: 'Edit Balasan Default',
      subtitle: 'Pesan ini akan dikirim jika pengirim chat di luar kata kunci terdaftar.',
      initialValue: widget.settings.defaultReply,
      hintText: 'Tulis pesan sapaan atau balasan default Anda...',
      icon: Icons.edit_note,
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        widget.settings.defaultReply = result;
      });
      await StorageService.saveSettings(widget.settings);
      widget.onSettingsChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.settings.isAutoReplyEnabled;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00A884), Color(0xFF056162)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A884).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MaoneAuto',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isEnabled ? const Color(0xFF00A884) : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isEnabled ? 'Service Aktif' : 'Service Dijeda',
                      style: TextStyle(
                        fontSize: 11,
                        color: isEnabled ? const Color(0xFF00A884) : Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A884),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
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
                message: 'Bot WhatsApp lokal siap memantau notifikasi dan membalas otomatis di latar belakang.',
              );
            },
            tooltip: 'Status Gateway',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Permission Warning Banner jika Akses Notifikasi belum aktif
            if (!widget.isNotificationPermissionGranted)
              _buildPermissionWarningBanner(),

            // 1. Hero Master Card: Balasan otomatis HIDUP / MATI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isEnabled
                      ? [const Color(0xFF13232B), const Color(0xFF0F1B22)]
                      : [const Color(0xFF141A1E), const Color(0xFF101518)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? const Color(0xFF00A884).withOpacity(0.35)
                      : Colors.white.withOpacity(0.06),
                  width: 1.2,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00A884).withOpacity(0.12),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? const Color(0xFF00A884).withOpacity(0.15)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEnabled ? Icons.mark_chat_read : Icons.mark_chat_unread_outlined,
                      color: isEnabled ? const Color(0xFF00A884) : Colors.white38,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEnabled ? 'Balasan Otomatis Aktif' : 'Balasan Otomatis Nonaktif',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isEnabled
                              ? 'Merespons pesan masuk via Android Notification Service'
                              : 'Layanan balasan otomatis sedang dimatikan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isEnabled,
                    onChanged: _toggleAutoReply,
                    activeColor: const Color(0xFF00A884),
                    activeTrackColor: const Color(0xFF00A884).withOpacity(0.4),
                    inactiveThumbColor: Colors.white60,
                    inactiveTrackColor: Colors.white12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Card Balasan Default (Elegan dengan Bubble Preview)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.reply_all, size: 18, color: Color(0xFF00A884)),
                          const SizedBox(width: 8),
                          const Text(
                            'Teks Balasan Default',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A884),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: _editDefaultReply,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, size: 13, color: Color(0xFF00A884)),
                              SizedBox(width: 4),
                              Text(
                                'Ubah',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A884),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Chat Bubble Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.settings.defaultReply,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Sekarang',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.done_all, size: 14, color: Color(0xFF53BDEB)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Section: Buat Balasan Otomatis (Fitur Cerdas MaoneAuto)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modul Balasan Cerdas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Pilih Konfigurasi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bento Grid 4 Fitur Utama
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: [
                // 1. Balasan AI
                _buildBentoCard(
                  title: 'Balasan AI',
                  subtitle: '9Router Gateway & Gemini Cloud',
                  icon: Icons.smart_toy_outlined,
                  accentColor: const Color(0xFF00D2A0),
                  tag: 'AI PRO',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiReplyScreen()),
                    );
                  },
                ),

                // 2. Balasan Kata Kunci
                _buildBentoCard(
                  title: 'Kata Kunci',
                  subtitle: 'Cocokan tepat / mengandung kata',
                  icon: Icons.key_outlined,
                  accentColor: const Color(0xFFF59E0B),
                  tag: 'KEYWORD',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KeywordReplyListScreen()),
                    );
                  },
                ),

                // 3. Menu Balas (Pohon Menu)
                _buildBentoCard(
                  title: 'Menu Balas',
                  subtitle: 'Katalog interaktif bertingkat',
                  icon: Icons.account_tree_outlined,
                  accentColor: const Color(0xFF10B981),
                  tag: 'TREE BOT',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MenuReplyScreen()),
                    );
                  },
                ),

                // 4. Google Sheets
                _buildBentoCard(
                  title: 'Google Sheets',
                  subtitle: 'Koneksi spreadsheet online',
                  icon: Icons.table_chart_outlined,
                  accentColor: const Color(0xFF38BDF8),
                  tag: 'SHEETS',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpreadsheetSyncScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Quick Simulator Launcher Card
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TestReplySimulatorScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF00A884).withOpacity(0.15),
                      const Color(0xFF111B21),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00A884).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A884).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phonelink_setup, color: Color(0xFF00A884), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggapan Uji / Simulator',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Uji coba alur balasan menu & keyword di sini',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Color(0xFF00A884), size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String tag,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111B21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF23180F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.priority_high_rounded, color: Colors.black, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Akses Notifikasi Belum Aktif!',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'MaoneAuto memerlukan izin "Akses Notifikasi" di pengaturan HP agar dapat mendeteksi chat WhatsApp masuk dan membalas otomatis.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              icon: const Icon(Icons.settings_outlined, color: Colors.black, size: 18),
              label: const Text(
                'AKTIFKAN SEKARANG DI PENGATURAN',
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                if (widget.onRequestPermission != null) {
                  widget.onRequestPermission!();
                } else {
                  MethodChannel('com.maoneart.maoneauto/service')
                      .invokeMethod('openNotificationSettings');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
