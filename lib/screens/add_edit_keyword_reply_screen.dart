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
  bool _useGoogleSheets = false;
  bool _sendEmail = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      final r = widget.existingRule!;
      _keywordController.text = r.incomingKeywords;
      _replyController.text = r.replyMessage;
      _isExactMatch = r.isExactMatch;
      _useMenuReply = r.useMenuReply;
      _useAiReply = r.useAiReply;
      _useGoogleSheets = r.useGoogleSheets;
      _sendEmail = r.sendEmailNotification;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _insertTag(String tag) {
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
    final rawText = _replyController.text.trim();
    if (rawText.isEmpty) {
      if (_useMenuReply) {
        return '📋 [Menu Balas Aktif]\n(Pohon menu otomatis terkirim)';
      }
      if (_useAiReply) {
        return '🤖 [Balasan AI Aktif]\n(Dijawab otomatis oleh AI)';
      }
      if (_useGoogleSheets) {
        return '📊 [Google Sheets Aktif]\n(Data spreadsheet terkirim)';
      }
      return 'Ketik pesan balasan Anda';
    }

    // Resolusi tag dinamis (nama contoh, jam saat ini, tanggal hari ini, hari ini)
    var rendered = AutoReplyEngine.applyTags(
      rawText,
      senderId: 'Budi Santoso',
    );

    if (_useMenuReply) {
      rendered = '$rendered\n\n📋 [+ Menu Balas terlampir]';
    } else if (_useAiReply) {
      rendered = '$rendered\n\n🤖 [+ Jawaban AI terlampir]';
    } else if (_useGoogleSheets) {
      rendered = '$rendered\n\n📊 [+ Data Sheets terlampir]';
    }

    return rendered;
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

    final hasDynamicSource = _useMenuReply || _useAiReply || _useGoogleSheets;
    if (reply.isEmpty && !hasDynamicSource) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis pesan balasan, atau centang salah satu Opsi Balasan (Menu Balas / AI / Google Sheets)!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final result = KeywordReply(
      id: widget.existingRule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      incomingKeywords: keywords,
      replyMessage: reply,
      isExactMatch: _isExactMatch,
      isEnabled: widget.existingRule?.isEnabled ?? true,
      useMenuReply: _useMenuReply,
      useAiReply: _useAiReply,
      useGoogleSheets: _useGoogleSheets,
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
                  // Field 1: Keyword Masuk
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _keywordController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Keyword Masuk',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Contoh: harga, biaya, berapa',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Field 2: Balas pesan
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2C34),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _replyController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Balas pesan (opsional jika memilih opsi di bawah)',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Contoh: Harga kami mulai dari 100. (Boleh kosong jika Menu Balas / AI dicentang)',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
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

                  // Section: Opsi balasan
                  const Text(
                    'Opsi balasan',
                    style: TextStyle(
                      color: Color(0xFF00A884),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildCheckboxTile(
                        label: 'Menu Balas',
                        value: _useMenuReply,
                        onChanged: (v) => setState(() => _useMenuReply = v ?? false),
                      ),
                      const SizedBox(width: 14),
                      _buildCheckboxTile(
                        label: 'ChatGPT / AI',
                        value: _useAiReply,
                        onChanged: (v) => setState(() => _useAiReply = v ?? false),
                      ),
                      const SizedBox(width: 14),
                      _buildCheckboxTile(
                        label: 'Google Sheets',
                        value: _useGoogleSheets,
                        onChanged: (v) => setState(() => _useGoogleSheets = v ?? false),
                      ),
                    ],
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
