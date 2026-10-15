import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';
import 'menu_reply_screen.dart';
import 'test_reply_simulator_screen.dart';
import 'keyword_reply_list_screen.dart';
import 'ai_reply_screen.dart';
import 'spreadsheet_sync_screen.dart';
import 'welcome_message_screen.dart';
import 'webhook_server_screen.dart';
import 'quick_notes_screen.dart';

class ToolsTab extends StatefulWidget {
  final AppSettings settings;
  final VoidCallback onSettingsChanged;

  const ToolsTab({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<ToolsTab> createState() => _ToolsTabState();
}

class _ToolsTabState extends State<ToolsTab> {
  void _showSupportedAppsModal(BuildContext context) {
    final supported = Map<String, bool>.from(widget.settings.supportedApps);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF111B21).withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A884).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.apps, color: Color(0xFF00A884), size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Aplikasi yang Didukung',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih aplikasi pesan yang ingin Anda balas otomatis:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.65),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildAppSwitchRow('WhatsApp', supported, setModalState),
                  _buildAppSwitchRow('WhatsApp Business', supported, setModalState),
                  _buildAppSwitchRow('Telegram', supported, setModalState),
                  _buildAppSwitchRow('Messenger', supported, setModalState),

                  const SizedBox(height: 20),
                  // 100% Simetris 2-Kolom Grid
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              widget.settings.supportedApps = supported;
                              await StorageService.saveSettings(widget.settings);
                              widget.onSettingsChanged();
                              if (ctx.mounted) Navigator.of(ctx).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A884),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Simpan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppSwitchRow(
    String appName,
    Map<String, bool> map,
    StateSetter setModalState,
  ) {
    final isChecked = map[appName] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B141B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Switch(
              value: isChecked,
              onChanged: (v) {
                setModalState(() {
                  map[appName] = v;
                });
              },
              activeColor: const Color(0xFF00A884),
              activeTrackColor: const Color(0xFF00A884).withOpacity(0.4),
              inactiveThumbColor: Colors.white60,
              inactiveTrackColor: Colors.white12,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Pusat Alat & Fitur',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TestReplySimulatorScreen()),
              );
            },
            tooltip: 'Simulator Chat',
          ),
          IconButton(
            icon: const Icon(Icons.send_outlined, color: Colors.white70),
            onPressed: () {
              GlassmorphismModal.showAlertModal(
                context: context,
                title: 'Server Status',
                message: '9Router AI Gateway aktif di port 20128 & Apache Webhook di port 8085.',
              );
            },
            tooltip: 'Status Server',
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
          children: [
            // Header Profile User (MaoneArt Signature Glass Card)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF13222B), Color(0xFF0F1B22)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00A884).withOpacity(0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A884), Color(0xFF10B981)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A884).withOpacity(0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                          child: const Icon(Icons.star, color: Colors.white, size: 10),
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
                          'Her Mawan (MaoneArt)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium, color: Color(0xFFF59E0B), size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'VIP Lifetime',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00A884).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00A884),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Layanan lokal termux disinkronkan.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Sinkronkan Layanan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Grid Menu 9 Alat Cerdas (Elevated Bento-Style)
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.96,
              children: [
                // 1. Aplikasi yang Didukung
                _buildToolCard(
                  icon: Icons.apps,
                  accentColor: const Color(0xFF38BDF8),
                  title: 'Aplikasi Terhubung',
                  subtitle: 'Pilih WhatsApp, Telegram, atau Messenger.',
                  onTap: () => _showSupportedAppsModal(context),
                ),

                // 2. Balasan Kata Kunci
                _buildToolCard(
                  icon: Icons.chat_outlined,
                  accentColor: const Color(0xFFF59E0B),
                  title: 'Kata Kunci',
                  subtitle: 'Balasan otomatis sesuai kata kunci masuk.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const KeywordReplyListScreen()),
                    );
                  },
                ),

                // 3. Balasan AI
                _buildToolCard(
                  icon: Icons.smart_toy_outlined,
                  accentColor: const Color(0xFF10B981),
                  title: 'Balasan AI',
                  subtitle: '9Router lokal port 20128 & model Gemini.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AiReplyScreen()),
                    );
                  },
                ),

                // 4. Lembar Kerja
                _buildToolCard(
                  icon: Icons.table_chart_outlined,
                  accentColor: const Color(0xFF06B6D4),
                  title: 'Lembar Kerja',
                  subtitle: 'Hubungkan Google Sheet untuk katalog harga.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SpreadsheetSyncScreen()),
                    );
                  },
                ),

                // 5. Menu Balas
                _buildToolCard(
                  icon: Icons.forum_outlined,
                  accentColor: const Color(0xFF00A884),
                  title: 'Menu Balas',
                  subtitle: 'Pohon menu opsi bertingkat untuk pelanggan.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MenuReplyScreen()),
                    );
                  },
                ),

                // 6. Pesan Selamat Datang
                _buildToolCard(
                  icon: Icons.waving_hand_outlined,
                  accentColor: const Color(0xFFEC4899),
                  title: 'Pesan Sambutan',
                  subtitle: 'Kirim sapaan hangat saat pelanggan pertama chat.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WelcomeMessageScreen()),
                    );
                  },
                ),

                // 7. Webhook Server
                _buildToolCard(
                  icon: Icons.dns_outlined,
                  accentColor: const Color(0xFF8B5CF6),
                  title: 'Webhook Server',
                  subtitle: 'Respon dinamis dari backend lokal port 8085.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WebhookServerScreen()),
                    );
                  },
                ),

                // 8. Tanggapan Uji (Simulator)
                _buildToolCard(
                  icon: Icons.phonelink_setup,
                  accentColor: const Color(0xFF14B8A6),
                  title: 'Tanggapan Uji',
                  subtitle: 'Simulator chat interaktif untuk menguji respon bot.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestReplySimulatorScreen()),
                    );
                  },
                ),

                // 9. Catatan Cepat
                _buildToolCard(
                  icon: Icons.note_alt_outlined,
                  accentColor: const Color(0xFFF97316),
                  title: 'Catatan Cepat',
                  subtitle: 'Buat memo & template teks pesan bisnis.',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuickNotesScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolCard({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
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
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
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
}
