import 'package:flutter/material.dart';
import '../models/keyword_reply.dart';
import '../services/auto_reply_engine.dart';
import '../widgets/glassmorphism_modal.dart';

class AddEditKeywordReplyScreen extends StatefulWidget {
  final KeywordReply? existingRule;

  const AddEditKeywordReplyScreen({super.key, this.existingRule});

  @override
  State<AddEditKeywordReplyScreen> createState() => _AddEditKeywordReplyScreenState();
}

class _AddEditKeywordReplyScreenState extends State<AddEditKeywordReplyScreen> {
  final TextEditingController _keywordController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();

  bool _isExactMatch = true;
  bool _useMenuReply = false;
  bool _useAiReply = false;
  bool _useWebhook = false;
  bool _sendEmail = false;

  bool get _isOptionLocked => _useMenuReply || _useAiReply || _useWebhook;

  String get _lockedOptionName {
    if (_useMenuReply) return 'Menu Balas';
    if (_useAiReply) return 'ChatGPT / AI';
    if (_useWebhook) return 'Web Server';
    return '';
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      final r = widget.existingRule!;
      _keywordController.text = r.incomingKeywords;
      _isExactMatch = r.isExactMatch;
      _useMenuReply = r.useMenuReply;
      _useAiReply = r.useAiReply;
      _useWebhook = r.useWebhook;
      _sendEmail = r.sendEmailNotification;
      if (_useMenuReply) {
        _replyController.text = 'Menu Balas';
      } else if (_useAiReply) {
        _replyController.text = 'ChatGPT / AI';
      } else if (_useWebhook) {
        _replyController.text = 'Web Server';
      } else {
        _replyController.text = r.replyMessage;
      }
    }
  }

  void _selectReplyOption(String option) {
    setState(() {
      switch (option) {
        case 'menu':
          _useMenuReply = !_useMenuReply;
          if (_useMenuReply) {
            _useAiReply = false;
            _useWebhook = false;
            _replyController.text = 'Menu Balas';
          } else {
            if (_replyController.text == 'Menu Balas') {
              _replyController.clear();
            }
          }
          break;
        case 'ai':
          _useAiReply = !_useAiReply;
          if (_useAiReply) {
            _useMenuReply = false;
            _useWebhook = false;
            _replyController.text = 'ChatGPT / AI';
          } else {
            if (_replyController.text == 'ChatGPT / AI') {
              _replyController.clear();
            }
          }
          break;
        case 'webhook':
          _useWebhook = !_useWebhook;
          if (_useWebhook) {
            _useMenuReply = false;
            _useAiReply = false;
            _replyController.text = 'Web Server';
          } else {
            if (_replyController.text == 'Web Server') {
              _replyController.clear();
            }
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
    if (_isOptionLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kolom balasan sedang terkunci otomatis ($_lockedOptionName).'),
          backgroundColor: const Color(0xFF1F2C34),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final text = _replyController.text;
    final selection = _replyController.selection;
    final insertText = '{{$tag}}';

    if (selection.start >= 0) {
      final newText = text.replaceRange(selection.start, selection.end, insertText);
      _replyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + insertText.length),
      );
    } else {
      _replyController.text = text.isEmpty ? insertText : '$text $insertText';
      _replyController.selection = TextSelection.collapsed(offset: _replyController.text.length);
    }
    setState(() {});
  }

  String _formatPreviewText() {
    if (_useMenuReply) {
      return '📋 [Menu Balas Aktif]\n(Pohon menu otomatis terkirim)';
    }
    if (_useAiReply) {
      return '🤖 [Balasan AI Aktif]\n(Dijawab otomatis oleh AI)';
    }
    if (_useWebhook) {
      return '🌐 [Web Server Aktif]\n(Dijawab otomatis oleh Server Webhook)';
    }

    final rawText = _replyController.text.trim();
    if (rawText.isEmpty) {
      return 'Ketik pesan balasan Anda';
    }

    // Resolusi tag dinamis (nama contoh, jam saat ini, tanggal hari ini, hari ini)
    return AutoReplyEngine.applyTags(
      rawText,
      senderId: 'Budi Santoso',
    );
  }

  void _saveRule() {
    final keywords = _keywordController.text.trim();
    final reply = _replyController.text.trim();

    if (keywords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keyword masuk tidak boleh kosong!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final hasDynamicSource = _useMenuReply || _useAiReply || _useWebhook;
    if (reply.isEmpty && !hasDynamicSource) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis pesan balasan, atau pilih salah satu Opsi Balasan (Menu Balas / AI / Web Server)!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = KeywordReply(
      id: widget.existingRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      incomingKeywords: keywords,
      replyMessage: _isOptionLocked ? _lockedOptionName : reply,
      isExactMatch: _isExactMatch,
      isEnabled: widget.existingRule?.isEnabled ?? true,
      useMenuReply: _useMenuReply,
      useAiReply: _useAiReply,
      useWebhook: _useWebhook,
      sendEmailNotification: _sendEmail,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingRule != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Edit Balasan Kata Kunci' : 'Tambah Balasan Kata Kunci',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF00A884), size: 28),
            onPressed: _saveRule,
            tooltip: 'Simpan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Chat Header (Seperti di Screenshot 3)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              color: const Color(0xFF182229),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bubble Pesan Masuk (Kiri - Putih)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                          bottomLeft: Radius.circular(2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _keywordController.text.trim().isEmpty
                            ? 'Ketik pesan masuk di bawah ini'
                            : _keywordController.text.trim(),
                        style: TextStyle(
                          color: _keywordController.text.trim().isEmpty
                              ? Colors.black54
                              : const Color(0xFF111B21),
                          fontSize: 14,
                          fontWeight: _keywordController.text.trim().isEmpty
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bubble Balasan (Kanan - Hijau Muda WhatsApp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9FDD3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        _formatPreviewText(),
                        style: TextStyle(
                          color: _replyController.text.trim().isEmpty
                              ? const Color(0xFF4B6E55)
                              : const Color(0xFF111B21),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Field 1: Keyword Masuk dengan Tombol Cepat "Semua (*)" di atasnya
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Keyword Masuk',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (_keywordController.text.trim() == '*') {
                              _keywordController.clear();
                            } else {
                              _keywordController.text = '*';
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _keywordController.text.trim() == '*'
                                ? const Color(0xFF00A884)
                                : const Color(0xFF00A884).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00A884),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.all_inclusive_rounded,
                                size: 14,
                                color: _keywordController.text.trim() == '*'
                                    ? Colors.white
                                    : const Color(0xFF00A884),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Semua (*)',
                                style: TextStyle(
                                  color: _keywordController.text.trim() == '*'
                                      ? Colors.white
                                      : const Color(0xFF00A884),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _keywordController.text.trim() == '*'
                            ? const Color(0xFF00A884).withOpacity(0.6)
                            : Colors.white.withOpacity(0.08),
                        width: _keywordController.text.trim() == '*' ? 1.5 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _keywordController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Keyword Masuk (misal: ass//askum//assalamuallaikum)',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 13.5),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _keywordController.text.trim() == '*'
                          ? '⭐ Mode Balas Semua: Menangkap APAPUN pesan masuk (Wildcard).'
                          : 'Bisa banyak variasi kata/typo dipisah "//" atau koma (misal: ass//askum//assalamuallaikum atau harga, biaya)',
                      style: TextStyle(
                        color: _keywordController.text.trim() == '*'
                            ? const Color(0xFF00A884)
                            : Colors.white38,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Field 2: Balas pesan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Balas pesan',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isOptionLocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00A884).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF00A884)),
                              const SizedBox(width: 4),
                              Text(
                                'Terkunci ($_lockedOptionName)',
                                style: const TextStyle(color: Color(0xFF00A884), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: _isOptionLocked ? const Color(0xFF141D22) : const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isOptionLocked ? const Color(0xFF00A884).withOpacity(0.4) : Colors.white.withOpacity(0.08),
                        width: _isOptionLocked ? 1.5 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _replyController,
                      readOnly: _isOptionLocked,
                      style: TextStyle(
                        color: _isOptionLocked ? const Color(0xFF00A884) : Colors.white,
                        fontSize: 15,
                        fontWeight: _isOptionLocked ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: _isOptionLocked ? 1 : 4,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _isOptionLocked ? _lockedOptionName : 'Balas pesan (opsional jika memilih opsi di bawah)',
                        hintStyle: TextStyle(
                          color: _isOptionLocked ? const Color(0xFF00A884).withOpacity(0.7) : Colors.white54,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _isOptionLocked
                          ? '🔒 Terisi otomatis dan dikunci karena opsi "$_lockedOptionName" aktif.'
                          : 'Contoh: Harga kami mulai dari 100. (Atau pilih opsi di bawah)',
                      style: TextStyle(
                        color: _isOptionLocked ? const Color(0xFF00A884) : Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Section: Tag (Slider horizontal 1 baris)
                  Row(
                    children: [
                      const Text(
                        'Tag Variabel',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          GlassmorphismModal.showAlertModal(
                            context: context,
                            title: 'Tag Variabel Pesan',
                            message:
                                'Gunakan tag untuk menyisipkan variabel dinamis ke pesan balasan:\n\n'
                                '• {{nama}} : Nama kontak pengirim (atau "Kak" jika belum disimpan)\n'
                                '• {{nama_depan}} : Nama depan kontak\n'
                                '• {{nama_belakang}} : Nama belakang kontak\n'
                                '• {{jam}} : Waktu saat ini (contoh: 14:30)\n'
                                '• {{tanggal}} : Tanggal hari ini (contoh: 15 Oktober 2026)\n'
                                '• {{hari}} : Nama hari ini (contoh: Kamis)\n'
                                '• {{pesan}} : Teks pesan masuk dari pengirim',
                          );
                        },
                        child: const Icon(Icons.info_outline, color: Colors.white54, size: 18),
                      ),
                      const Spacer(),
                      const Text(
                        'Geser ➡️',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildTagChip('nama', 'nama', Icons.person_outline),
                        const SizedBox(width: 8),
                        _buildTagChip('nama depan', 'nama_depan', Icons.badge_outlined),
                        const SizedBox(width: 8),
                        _buildTagChip('nama belakang', 'nama_belakang', Icons.assignment_ind_outlined),
                        const SizedBox(width: 8),
                        _buildTagChip('jam', 'jam', Icons.access_time),
                        const SizedBox(width: 8),
                        _buildTagChip('tanggal', 'tanggal', Icons.calendar_today_outlined),
                        const SizedBox(width: 8),
                        _buildTagChip('hari', 'hari', Icons.today_outlined),
                        const SizedBox(width: 8),
                        _buildTagChip('pesan', 'pesan', Icons.chat_bubble_outline),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Opsi balasan (Hanya bisa dipilih 1)
                  Row(
                    children: [
                      const Text(
                        'Opsi balasan',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Pilih salah 1',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildCheckboxTile(
                          label: 'Menu Balas',
                          value: _useMenuReply,
                          onChanged: (_) => _selectReplyOption('menu'),
                        ),
                        const SizedBox(width: 14),
                        _buildCheckboxTile(
                          label: 'ChatGPT / AI',
                          value: _useAiReply,
                          onChanged: (_) => _selectReplyOption('ai'),
                        ),
                        const SizedBox(width: 14),
                        _buildCheckboxTile(
                          label: 'Web Server',
                          value: _useWebhook,
                          onChanged: (_) => _selectReplyOption('webhook'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section: Opsi pencocokan
                  Row(
                    children: [
                      const Text(
                        'Opsi pencocokan',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          GlassmorphismModal.showAlertModal(
                            context: context,
                            title: 'Opsi Pencocokan Kata Kunci',
                            message:
                                '• Cocokan Tepat: Pesan masuk harus persis sama dengan kata kunci.\n• Mengandung: Pesan akan dibalas jika mengandung salah satu kata kunci tersebut di dalam kalimat.',
                          );
                        },
                        child: const Icon(Icons.help_outline, color: Colors.white54, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRadioTile(
                        title: 'Cocokan Tepat',
                        value: true,
                        groupValue: _isExactMatch,
                        onChanged: (v) => setState(() => _isExactMatch = v ?? true),
                      ),
                      const SizedBox(width: 20),
                      _buildRadioTile(
                        title: 'Mengandung',
                        value: false,
                        groupValue: _isExactMatch,
                        onChanged: (v) => setState(() => _isExactMatch = v ?? false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section: Pemberitahuan Balasan
                  Row(
                    children: [
                      const Text(
                        'Pemberitahuan Balasan',
                        style: TextStyle(
                          color: Color(0xFF00A884),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          GlassmorphismModal.showAlertModal(
                            context: context,
                            title: 'Pemberitahuan Email',
                            message:
                                'Kirimkan notifikasi ringkasan percakapan otomatis ke alamat email yang terdaftar setiap kali kata kunci ini dipicu.',
                          );
                        },
                        child: const Icon(Icons.help_outline, color: Colors.white54, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildCheckboxTile(
                    label: 'Kirim Email',
                    value: _sendEmail,
                    onChanged: (v) => setState(() => _sendEmail = v ?? false),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String displayLabel, String tagKey, [IconData? icon]) {
    return InkWell(
      onTap: () => _insertTag(tagKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF111B21),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00A884).withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF00A884), size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              displayLabel,
              style: const TextStyle(
                color: Color(0xFF00A884),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF00A884),
              checkColor: Colors.white,
              side: const BorderSide(color: Colors.white54, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required bool value,
    required bool groupValue,
    required ValueChanged<bool?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF00A884) : Colors.white54,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00A884),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
