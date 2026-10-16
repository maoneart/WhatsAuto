import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/webhook_service.dart';
import '../utils/webhook_code_templates.dart';
import '../widgets/glassmorphism_modal.dart';

class WebhookServerScreen extends StatefulWidget {
  const WebhookServerScreen({super.key});

  @override
  State<WebhookServerScreen> createState() => _WebhookServerScreenState();
}

class _WebhookServerScreenState extends State<WebhookServerScreen> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isTesting = false;
  final TextEditingController _urlController = TextEditingController();
  String _testResponse = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await StorageService.loadSettings();
    setState(() {
      _settings = s;
      _urlController.text = s.serverWebhookUrl;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    _settings.serverWebhookUrl = _urlController.text.trim();
    await StorageService.saveSettings(_settings);
  }

  Future<void> _testWebhook() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      GlassmorphismModal.showAlertModal(
        context: context,
        title: 'URL Diperlukan',
        message: 'Silakan masukkan URL Webhook Server terlebih dahulu.',
      );
      return;
    }

    setState(() {
      _isTesting = true;
      _testResponse = '';
    });

    try {
      final reply = await WebhookService.testWebhook(url);
      setState(() {
        _testResponse = '✅ Respon Server Diterima:\n"$reply"';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResponse = '❌ Gagal Terhubung: ${e.toString().replaceFirst("Exception: ", "")}';
        _isTesting = false;
      });
    }
  }

  void _applyPreset(String url) {
    setState(() {
      _urlController.text = url;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
      );
    }

    final isEnabled = _urlController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Webhook Server',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Status Hero Card
            _buildStatusCard(isEnabled),
            const SizedBox(height: 16),

            // 2. Input URL Webhook
            _buildUrlInputCard(),
            const SizedBox(height: 16),

            // 3. Template Script Webhook Siap Pakai
            _buildTemplatesCard(),
            const SizedBox(height: 16),

            // 4. Preset Cepat Port Lokal Termux
            _buildLocalPresets(),
            const SizedBox(height: 16),

            // 5. Spesifikasi Payload JSON
            _buildPayloadSpecs(),
            const SizedBox(height: 16),

            // 6. Tombol Uji Ping Webhook
            _buildTestButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(bool isEnabled) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? const Color(0xFF8B5CF6).withOpacity(0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (isEnabled)
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isEnabled ? const Color(0xFF8B5CF6) : Colors.white12).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dns_rounded,
              color: isEnabled ? const Color(0xFF8B5CF6) : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Integrasi Webhook Server',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  isEnabled
                      ? 'Terhubung — Pesan diteruskan ke backend API server'
                      : 'Nonaktif — Masukkan URL server untuk mengaktifkan',
                  style: TextStyle(
                    color: isEnabled ? const Color(0xFF8B5CF6) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'URL Server Endpoint (POST)',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'http://127.0.0.1:8085/api/whatsapp',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0B141B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              suffixIcon: _urlController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _urlController.clear();
                        _saveSettings();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) {
              _saveSettings();
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocalPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preset Server Lokal Termux:',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ActionChip(
              backgroundColor: const Color(0xFF111B21),
              side: const BorderSide(color: Colors.white12),
              label: const Text('Local Port 8085 (Apache/PHP)', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
              onPressed: () => _applyPreset('http://127.0.0.1:8085/api/reply.php'),
            ),
            ActionChip(
              backgroundColor: const Color(0xFF111B21),
              side: const BorderSide(color: Colors.white12),
              label: const Text('Hermes Agent (Port 8088)', style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 11)),
              onPressed: () => _applyPreset('http://127.0.0.1:8088/webhook'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPayloadSpecs() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.code_rounded, color: Color(0xFF8B5CF6), size: 16),
              SizedBox(width: 6),
              Text(
                'Spesifikasi Payload JSON:',
                style: TextStyle(color: Color(0xFF8B5CF6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Request dikirim via POST JSON:\n{\n  "sender": "+628123...",\n  "message": "pesan pelanggan",\n  "app": "WhatsApp",\n  "timestamp": "2026-10-15T..."\n}',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
          ),
          SizedBox(height: 8),
          Text(
            'Respon yang diharapkan:\n{\n  "reply": "Teks balasan yang akan dikirim ke WhatsApp"\n}',
            style: TextStyle(color: Color(0xFF00A884), fontSize: 11, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isTesting ? null : _testWebhook,
            child: _isTesting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Uji Ping Webhook Sekarang', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
        if (_testResponse.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0B141B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(_testResponse, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ],
    );
  }

  Widget _buildTemplatesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00A884).withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A884).withOpacity(0.08),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00A884).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.code_rounded, color: Color(0xFF00A884), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Template Script Webhook Siap Pakai',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Google Apps Script (Gratis), PHP, Node.js & Python',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Bingung cara membuat webhook? Tinggal salin script siap pakai ke Google Apps Script (100% gratis tanpa sewa hosting) atau web server hosting Anda!',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showCodeTemplatesModal(context),
                    icon: const Icon(Icons.content_copy_rounded, color: Colors.white, size: 16),
                    label: const Text(
                      'Salin Template',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Clipboard.setData(const ClipboardData(text: WebhookCodeTemplates.githubTemplatesUrl));
                      GlassmorphismModal.showAlertModal(
                        context: context,
                        title: 'Link GitHub Disalin',
                        message: 'Link repositori template script webhook telah disalin ke clipboard:\n\n${WebhookCodeTemplates.githubTemplatesUrl}\n\nAnda dapat membuka link ini di browser untuk mengunduh semua file template secara langsung.',
                        iconColor: const Color(0xFF00A884),
                        icon: Icons.check_circle_outline,
                      );
                    },
                    icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white70, size: 16),
                    label: const Text(
                      'Link GitHub',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCodeTemplatesModal(BuildContext context) {
    int selectedIndex = 0;
    final List<Map<String, dynamic>> templates = [
      {
        'title': 'Google Apps Script',
        'badge': 'Gratis 100%',
        'code': WebhookCodeTemplates.gasTemplate,
        'info': 'Buka script.google.com -> Buat project -> Paste kode -> Deploy as Web App (Who has access: Anyone) -> Salin Web App URL ke aplikasi ini.',
      },
      {
        'title': 'PHP',
        'badge': 'Hosting/Apache',
        'code': WebhookCodeTemplates.phpTemplate,
        'info': 'Upload ke cPanel/Apache/Nginx di hosting Anda (misal https://domainanda.com/webhook.php).',
      },
      {
        'title': 'Node.js',
        'badge': 'Express',
        'code': WebhookCodeTemplates.nodeTemplate,
        'info': 'Jalankan di VPS, PC lokal, atau Termux. Install express lalu jalankan server node.',
      },
      {
        'title': 'Python',
        'badge': 'Flask',
        'code': WebhookCodeTemplates.pythonTemplate,
        'info': 'Jalankan di server Python menggunakan Flask (pip install flask).',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final current = templates[selectedIndex];
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFF111B21),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Color(0xFF00A884), width: 1.5),
                  left: BorderSide(color: Colors.white12),
                  right: BorderSide(color: Colors.white12),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.code_rounded, color: Color(0xFF00A884), size: 24),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Template Kode Webhook',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white60),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),

                  // Tab Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: List.generate(templates.length, (index) {
                        final isSelected = selectedIndex == index;
                        final item = templates[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item['title'] as String),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : const Color(0xFF00A884).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item['badge'] as String,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF00A884),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: const Color(0xFF00A884),
                            backgroundColor: const Color(0xFF1F2C34),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  selectedIndex = index;
                                });
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),

                  // Info box singkat
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF00A884), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            current['info'] as String,
                            style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Code preview box
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B141B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          current['code'] as String,
                          style: const TextStyle(
                            color: Color(0xFFE9EDEF),
                            fontSize: 11,
                            fontFamily: 'monospace',
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom action buttons (Glassmorphism 2-column symmetric)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00A884),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: current['code'] as String));
                                Navigator.pop(ctx);
                                GlassmorphismModal.showAlertModal(
                                  context: context,
                                  title: 'Kode Berhasil Disalin!',
                                  message: 'Template kode ${current['title']} telah disalin ke clipboard.\n\nSilakan paste ke platform tujuan Anda, lalu salin URL webhook yang dihasilkan ke MaoneAuto.',
                                  iconColor: const Color(0xFF00A884),
                                  icon: Icons.check_circle_outline,
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Salin Kode', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
