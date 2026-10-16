import 'package:flutter/material.dart';
import '../models/keyword_reply.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';
import 'add_edit_keyword_reply_screen.dart';

class KeywordReplyListScreen extends StatefulWidget {
  const KeywordReplyListScreen({super.key});

  @override
  State<KeywordReplyListScreen> createState() => _KeywordReplyListScreenState();
}

class _KeywordReplyListScreenState extends State<KeywordReplyListScreen> {
  List<KeywordReply> _rules = [];
  bool _isLoading = true;
  bool _isMasterEnabled = true;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final settings = await StorageService.loadSettings();
    final rules = await StorageService.loadKeywordReplies();

    setState(() {
      _isMasterEnabled = settings.isKeywordReplyEnabled;
      _rules = rules;
      _isLoading = false;
    });
  }

  Future<void> _toggleMaster(bool val) async {
    final settings = await StorageService.loadSettings();
    settings.isKeywordReplyEnabled = val;
    await StorageService.saveSettings(settings);

    setState(() {
      _isMasterEnabled = val;
    });
  }

  Future<void> _toggleRule(int index, bool val) async {
    setState(() {
      _rules[index].isEnabled = val;
    });
    await StorageService.saveKeywordReplies(_rules);
  }

  Future<void> _addNewRule() async {
    final result = await Navigator.of(context).push<KeywordReply>(
      MaterialPageRoute(builder: (_) => const AddEditKeywordReplyScreen()),
    );

    if (result != null) {
      setState(() {
        _rules.add(result);
      });
      await StorageService.saveKeywordReplies(_rules);
    }
  }

  Future<void> _editRule(int index) async {
    final result = await Navigator.of(context).push<KeywordReply>(
      MaterialPageRoute(
        builder: (_) => AddEditKeywordReplyScreen(existingRule: _rules[index]),
      ),
    );

    if (result != null) {
      setState(() {
        _rules[index] = result;
      });
      await StorageService.saveKeywordReplies(_rules);
    }
  }

  Future<void> _deleteRule(int index) async {
    final confirmed = await GlassmorphismModal.showConfirmModal(
      context: context,
      title: 'Hapus Balasan Kata Kunci',
      message: 'Apakah Anda yakin ingin menghapus aturan balasan kata kunci ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline,
    );

    if (confirmed == true) {
      setState(() {
        _rules.removeAt(index);
      });
      await StorageService.saveKeywordReplies(_rules);
    }
  }

  void _showGenerateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C34),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Buat balasan otomatis dari....',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 1. Gambar
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Buat dari Gambar',
                      message:
                          'Ekstrak tanya-jawab otomatis dari tangkapan layar chat WhatsApp atau brosur menggunakan OCR AI.',
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.image_outlined, color: Color(0xFF00A884), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gambar',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Hasilkan balasan dari tangkapan layar obrolan atau gambar.',
                                style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(color: Colors.white.withOpacity(0.08), height: 1),

                // 2. Situs Web
                InkWell(
                  onTap: () {
                    Navigator.of(ctx).pop();
                    GlassmorphismModal.showAlertModal(
                      context: context,
                      title: 'Buat dari Situs Web',
                      message:
                          'Salin URL landing page produk atau toko online Anda untuk membuat daftar kata kunci dan respon otomatis.',
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.language, color: Color(0xFF00A884), size: 24),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Situs web',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Hasilkan balasan dari sebuah situs web.',
                                style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredRules = _rules.where((r) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return r.incomingKeywords.toLowerCase().contains(q) ||
          r.replyMessage.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Cari kata kunci...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text(
                'Balasan Kata Kunci',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white70),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.access_time, color: Colors.white70),
            onPressed: () {
              GlassmorphismModal.showAlertModal(
                context: context,
                title: 'Riwayat Pemicu Kata Kunci',
                message:
                    'Total aturan aktif: ${_rules.where((r) => r.isEnabled).length} dari ${_rules.length} aturan terdaftar.',
              );
            },
            tooltip: 'Riwayat',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onPressed: () {
              GlassmorphismModal.showAlertModal(
                context: context,
                title: 'Kelola Balasan Kata Kunci',
                message:
                    'Gunakan tombol Tambah (+) untuk membuat aturan baru, atau tombol Pensil untuk menghasilkan dari gambar/web.',
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : Column(
              children: [
                // Banner Master Switch (Screenshot 1)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  color: _isMasterEnabled ? const Color(0xFF005D4B) : const Color(0xFF1F2C34),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isMasterEnabled ? 'HIDUP' : 'MATI',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Switch(
                        value: _isMasterEnabled,
                        onChanged: _toggleMaster,
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF00A884),
                        inactiveThumbColor: Colors.white60,
                        inactiveTrackColor: Colors.white24,
                      ),
                    ],
                  ),
                ),

                // Content: Empty State vs List
                Expanded(
                  child: filteredRules.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredRules.length,
                          itemBuilder: (ctx, index) {
                            final rule = filteredRules[index];
                            return _buildRuleCard(rule, index);
                          },
                        ),
                ),
              ],
            ),
      // Dual Floating Action Buttons (Screenshot 1)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top FAB: Tambah (+)
          FloatingActionButton(
            heroTag: 'fab_add_keyword',
            backgroundColor: const Color(0xFF00A884),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _addNewRule,
            child: const Icon(Icons.add, size: 28),
          ),
          const SizedBox(height: 12),

          // Bottom FAB: Pensil (Buat otomatis)
          FloatingActionButton(
            heroTag: 'fab_ai_generate_keyword',
            backgroundColor: const Color(0xFF00A884),
            foregroundColor: Colors.white,
            elevation: 4,
            onPressed: _showGenerateModal,
            child: const Icon(Icons.edit, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon Balon Chat Hijau Tua (Persis Screenshot 1)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF00A884).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble,
                color: Color(0xFF00A884),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tambahkan balasan kata kunci',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Balasan dikirim secara otomatis ketika pesan cocok dengan kata kunci Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(KeywordReply rule, int index) {
    final keywordsList = rule.incomingKeywords
        .split(RegExp(r'//|,|\||\n|;'))
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: () => _editRule(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Atas: Chip Keywords & Toggle Switch
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: keywordsList.map((kw) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF00A884).withOpacity(0.3)),
                          ),
                          child: Text(
                            kw == '*' ? '⭐ Semua (*)' : kw,
                            style: const TextStyle(
                              color: Color(0xFF00A884),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: rule.isEnabled,
                    onChanged: (v) => _toggleRule(index, v),
                    activeColor: const Color(0xFF00A884),
                    inactiveThumbColor: Colors.white54,
                    inactiveTrackColor: Colors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Teks Balasan
              Text(
                rule.replyMessage.trim().isEmpty && (rule.useMenuReply || rule.useAiReply || rule.useWebhook)
                    ? (rule.useMenuReply
                        ? '📋 [Menampilkan Menu Balas Otomatis]'
                        : (rule.useAiReply ? '🤖 [Dibalas Otomatis oleh AI]' : '🌐 [Dibalas Otomatis via Web Server]'))
                    : rule.replyMessage,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // Baris Bawah: Badge Tipe Pencocokan & Tombol Hapus
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2C34),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rule.incomingKeywords.split(RegExp(r'//|,|\||\n|;')).any((k) => k.trim() == '*')
                              ? 'Balas Semua'
                              : (rule.isExactMatch ? 'Cocokan Tepat' : 'Mengandung'),
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
                        ),
                      ),
                      if (rule.useMenuReply) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Menu Balas',
                            style: TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                          ),
                        ),
                      ],
                      if (rule.useAiReply) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AI',
                            style: TextStyle(color: Colors.purpleAccent, fontSize: 11),
                          ),
                        ),
                      ],
                      if (rule.useWebhook) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Web Server',
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
                    onPressed: () => _deleteRule(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
