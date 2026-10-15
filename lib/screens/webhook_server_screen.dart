import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/webhook_service.dart';
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

            // 3. Preset Cepat Port Lokal Termux
            _buildLocalPresets(),
            const SizedBox(height: 16),

            // 4. Spesifikasi Payload JSON
            _buildPayloadSpecs(),
            const SizedBox(height: 16),

            // 5. Tombol Uji Ping Webhook
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
}
