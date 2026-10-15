import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/auto_reply_engine.dart';

class WelcomeMessageScreen extends StatefulWidget {
  const WelcomeMessageScreen({super.key});

  @override
  State<WelcomeMessageScreen> createState() => _WelcomeMessageScreenState();
}

class _WelcomeMessageScreenState extends State<WelcomeMessageScreen> {
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await StorageService.loadSettings();
    setState(() {
      _settings = s;
      _textController.text = s.welcomeMessage.isNotEmpty
          ? s.welcomeMessage
          : 'Halo {{nama}}! Selamat datang di MaoneArt. Ada yang bisa kami bantu hari ini? 😊';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    _settings.welcomeMessage = _textController.text.trim();
    await StorageService.saveSettings(_settings);
  }

  void _insertTag(String tag) {
    final text = _textController.text;
    final selection = _textController.selection;
    final newText = text.replaceRange(
      selection.start >= 0 ? selection.start : text.length,
      selection.end >= 0 ? selection.end : text.length,
      tag,
    );
    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: (selection.start >= 0 ? selection.start : text.length) + tag.length,
      ),
    );
    _saveSettings();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFEC4899))),
      );
    }

    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final previewText = AutoReplyEngine.applyTags(
      _textController.text.isNotEmpty ? _textController.text : 'Selamat datang di layanan kami!',
      senderId: 'Budi Santoso',
      now: now,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Pesan Sambutan',
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

            // 2. Info Aturan Sambutan
            _buildRuleInfoCard(),
            const SizedBox(height: 16),

            // 3. Live Chat Bubble Preview
            _buildLiveChatPreview(previewText, timeStr),
            const SizedBox(height: 16),

            // 4. Editor Teks Sambutan
            _buildEditorCard(),
            const SizedBox(height: 12),

            // 5. Variable Tag Selector
            _buildTagChips(),
          ],
        ),
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
          color: _settings.welcomeMessageEnabled ? const Color(0xFFEC4899).withOpacity(0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (_settings.welcomeMessageEnabled)
            BoxShadow(
              color: const Color(0xFFEC4899).withOpacity(0.12),
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
              color: (_settings.welcomeMessageEnabled ? const Color(0xFFEC4899) : Colors.white12).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              color: _settings.welcomeMessageEnabled ? const Color(0xFFEC4899) : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pesan Selamat Datang',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  _settings.welcomeMessageEnabled
                      ? 'Aktif — Sapa pelanggan baru secara otomatis'
                      : 'Nonaktif — Tidak mengirim pesan pembuka',
                  style: TextStyle(
                    color: _settings.welcomeMessageEnabled ? const Color(0xFFEC4899) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _settings.welcomeMessageEnabled,
            activeColor: const Color(0xFFEC4899),
            activeTrackColor: const Color(0xFFEC4899).withOpacity(0.4),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              setState(() => _settings.welcomeMessageEnabled = val);
              _saveSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRuleInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEC4899).withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFFEC4899), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pesan sambutan dikirim secara otomatis saat kontak atau nomor baru mengirim pesan ke WhatsApp Anda untuk pertama kalinya.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChatPreview(String text, String timeStr) {
    return Container(
      width: double.infinity,
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
              Icon(Icons.visibility_outlined, color: Color(0xFFEC4899), size: 16),
              SizedBox(width: 6),
              Text(
                'Live Pratinjau Balon Chat',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF005C4B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(timeStr, style: const TextStyle(color: Colors.white60, fontSize: 10)),
                      const SizedBox(width: 4),
                      const Icon(Icons.done_all, color: Color(0xFF53BDEB), size: 14),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard() {
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
            'Teks Pesan Sambutan',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _textController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tuliskan pesan pembuka...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0B141B),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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

  Widget _buildTagChips() {
    final tags = [
      {'label': 'Nama Pengirim', 'code': '{{nama}}'},
      {'label': 'Nama Depan', 'code': '{{nama_depan}}'},
      {'label': 'Jam', 'code': '{{jam}}'},
      {'label': 'Hari', 'code': '{{hari}}'},
      {'label': 'Tanggal', 'code': '{{tanggal}}'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sisipkan Tag Otomatis:',
          style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: tags.map((t) {
            return ActionChip(
              backgroundColor: const Color(0xFF111B21),
              side: const BorderSide(color: Colors.white12),
              label: Text(t['label']!, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 11)),
              onPressed: () => _insertTag(t['code']!),
            );
          }).toList(),
        ),
      ],
    );
  }
}
