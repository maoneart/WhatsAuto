import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';
import '../widgets/glassmorphism_modal.dart';

class AiReplyScreen extends StatefulWidget {
  const AiReplyScreen({super.key});

  @override
  State<AiReplyScreen> createState() => _AiReplyScreenState();
}

class _AiReplyScreenState extends State<AiReplyScreen> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isTesting = false;
  bool _obscureApiKey = true;

  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _testMessageController = TextEditingController();

  String _testResponse = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _apiKeyController.dispose();
    _testMessageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await StorageService.loadSettings();
    setState(() {
      _settings = s;
      _promptController.text = s.aiCustomPrompt.isNotEmpty
          ? s.aiCustomPrompt
          : 'Anda adalah Customer Support ramah MaoneAuto. Jawab pertanyaan pengguna dengan sopan, jelas, ringkas, dan solutif dalam bahasa Indonesia.';
      _apiKeyController.text = s.aiApiKey;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    _settings.aiCustomPrompt = _promptController.text.trim();
    _settings.aiApiKey = _apiKeyController.text.trim();
    await StorageService.saveSettings(_settings);
  }

  Future<void> _runTest() async {
    final testMsg = _testMessageController.text.trim();
    setState(() {
      _isTesting = true;
      _testResponse = '';
    });

    try {
      final reply = await AiService.testConnection(
        provider: _settings.aiProvider,
        apiKey: _apiKeyController.text.trim(),
        prompt: _promptController.text.trim(),
        testMessage: testMsg,
      );

      setState(() {
        _testResponse = reply;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResponse = '❌ Error: ${e.toString().replaceFirst("Exception: ", "")}';
        _isTesting = false;
      });
    }
  }

  void _applyTemplate(String prompt) {
    setState(() {
      _promptController.text = prompt;
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Balasan AI Pintar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Master Toggle
            _buildMasterToggle(),
            const SizedBox(height: 16),

            // 1b. Cakupan Penerima AI (Japri vs Grup Terpisah)
            _buildScopeCard(),
            const SizedBox(height: 16),

            // 2. Gateway Provider Selector
            _buildProviderCard(),
            const SizedBox(height: 16),

            // 3. API Key & Endpoint Card
            _buildEndpointCard(),
            const SizedBox(height: 16),

            // 4. System Prompt / Persona Bot
            _buildSystemPromptCard(),
            const SizedBox(height: 16),

            // 5. Kotak Pengujian Live Chat
            _buildLiveAiTester(),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeCard() {
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
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text(
                'Cakupan Balasan AI',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pisahkan sakelar untuk pesan pribadi (japri) dan grup agar tidak mengganggu obrolan grup.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 14),
          // Toggle Chat Pribadi (Japri)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_settings.aiReplyPersonal ? const Color(0xFF10B981) : Colors.white12).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: _settings.aiReplyPersonal ? const Color(0xFF10B981) : Colors.white54,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Pribadi (Japri)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _settings.aiReplyPersonal
                          ? 'Aktif — AI membalas pesan obrolan 1-lawan-1'
                          : 'Nonaktif — Abaikan chat pribadi',
                      style: TextStyle(
                        color: _settings.aiReplyPersonal ? const Color(0xFF10B981) : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings.aiReplyPersonal,
                activeColor: const Color(0xFF10B981),
                activeTrackColor: const Color(0xFF10B981).withOpacity(0.4),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white10,
                onChanged: _settings.aiReplyEnabled
                    ? (val) {
                        setState(() => _settings.aiReplyPersonal = val);
                        _saveSettings();
                      }
                    : null,
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white10, height: 1),
          ),
          // Toggle Chat Grup
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_settings.aiReplyGroup ? const Color(0xFF38BDF8) : Colors.white12).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: _settings.aiReplyGroup ? const Color(0xFF38BDF8) : Colors.white54,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chat Grup WhatsApp',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _settings.aiReplyGroup
                          ? 'Aktif — AI merespons di dalam grup'
                          : 'Nonaktif — AI tidak membalas di grup (Aman)',
                      style: TextStyle(
                        color: _settings.aiReplyGroup ? const Color(0xFF38BDF8) : Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _settings.aiReplyGroup,
                activeColor: const Color(0xFF38BDF8),
                activeTrackColor: const Color(0xFF38BDF8).withOpacity(0.4),
                inactiveThumbColor: Colors.white38,
                inactiveTrackColor: Colors.white10,
                onChanged: _settings.aiReplyEnabled
                    ? (val) {
                        setState(() => _settings.aiReplyGroup = val);
                        _saveSettings();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _settings.aiReplyEnabled ? const Color(0xFF10B981).withOpacity(0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (_settings.aiReplyEnabled)
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.12),
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
              color: (_settings.aiReplyEnabled ? const Color(0xFF10B981) : Colors.white12).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              color: _settings.aiReplyEnabled ? const Color(0xFF10B981) : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balasan AI Otomatis',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  _settings.aiReplyEnabled
                      ? 'Aktif — Membalas pesan menggunakan model AI cerdas'
                      : 'Nonaktif — AI tidak merespons pesan',
                  style: TextStyle(
                    color: _settings.aiReplyEnabled ? const Color(0xFF10B981) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings.aiReplyEnabled,
            activeColor: const Color(0xFF10B981),
            activeTrackColor: const Color(0xFF10B981).withOpacity(0.4),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              setState(() => _settings.aiReplyEnabled = val);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
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
            'Penyedia Mesin AI',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProviderOption(
                  id: '9router',
                  title: '9Router Gateway',
                  subtitle: 'Port 20128 Lokal',
                  icon: Icons.router_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildProviderOption(
                  id: 'gemini',
                  title: 'Google Gemini',
                  subtitle: 'Cloud API Langsung',
                  icon: Icons.auto_awesome_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _settings.aiProvider == id;
    return GestureDetector(
      onTap: () {
        setState(() => _settings.aiProvider = id);
        _saveSettings();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981).withOpacity(0.12) : const Color(0xFF0B141B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? const Color(0xFF10B981) : Colors.white54, size: 20),
                const Spacer(),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointCard() {
    final is9Router = _settings.aiProvider == '9router';

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
          Row(
            children: [
              Icon(is9Router ? Icons.memory : Icons.key, color: const Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Text(
                is9Router ? 'Alamat Gateway Lokal (Termux)' : 'Google Gemini API Key',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (is9Router) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B141B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt, color: Color(0xFF10B981), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'http://127.0.0.1:20128/v1/chat/completions',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gateway 9Router otomatis aktif di port 20128 dengan model gemini-2.5-flash.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ] else ...[
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'AIzaSy... / AQ....',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0B141B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureApiKey = !_obscureApiKey;
                    });
                  },
                  tooltip: _obscureApiKey ? 'Tampilkan API Key' : 'Sembunyikan API Key',
                ),
              ),
              onChanged: (_) => _saveSettings(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemPromptCard() {
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
            'Instruksi Persona Bot (System Prompt)',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tentukan karakter, nada bicara, dan aturan AI saat membalas pesan pelanggan.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _promptController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tuliskan persona bot Anda...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0B141B),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (_) => _saveSettings(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Template Cepat:',
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildTemplateChip(
                'CS Toko Online',
                'Anda adalah Customer Support ramah toko online. Jawab pertanyaan produk, harga, dan pengiriman dengan sopan dan singkat.',
              ),
              _buildTemplateChip(
                'Asisten Santai',
                'Kamu adalah teman chat yang santai, ceria, dan membantu menjawab pertanyaan dengan gaya akrab.',
              ),
              _buildTemplateChip(
                'Formal Bisnis',
                'Selamat datang di layanan resmi kami. Kami memberikan informasi kredibel dan profesional kepada mitra dan klien.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateChip(String label, String prompt) {
    return ActionChip(
      backgroundColor: const Color(0xFF0B141B),
      side: const BorderSide(color: Colors.white12),
      label: Text(label, style: const TextStyle(color: Color(0xFF10B981), fontSize: 11)),
      onPressed: () => _applyTemplate(prompt),
    );
  }

  Widget _buildLiveAiTester() {
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
          const Row(
            children: [
              Icon(Icons.chat_bubble_outline, color: Color(0xFF10B981), size: 18),
              SizedBox(width: 8),
              Text(
                'Uji Coba Respon AI Langsung',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testMessageController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan tes (misal: "Halo, jualan apa aja?")...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0B141B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (_) => _runTest(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isTesting ? null : _runTest,
                child: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Kirim', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_testResponse.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B141B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Balasan Model AI:', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(_testResponse, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
