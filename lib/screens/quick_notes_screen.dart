import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/quick_note_model.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';

class QuickNotesScreen extends StatefulWidget {
  const QuickNotesScreen({super.key});

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen> {
  List<QuickNote> _notes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    final list = await StorageService.loadQuickNotes();
    setState(() {
      _notes = list;
      _isLoading = false;
    });
  }

  Future<void> _saveNotes() async {
    await StorageService.saveQuickNotes(_notes);
  }

  void _showAddEditModal([QuickNote? existing]) {
    final isEdit = existing != null;
    final titleController = TextEditingController(text: existing?.title ?? '');
    final contentController = TextEditingController(text: existing?.content ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF111B21),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Ubah Catatan Cepat' : 'Tambah Catatan Baru',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Judul Memo',
                  labelStyle: const TextStyle(color: Color(0xFFF97316), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0B141B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Isi Teks Template',
                  labelStyle: const TextStyle(color: Color(0xFFF97316), fontSize: 12),
                  filled: true,
                  fillColor: const Color(0xFF0B141B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              // Simetris 2-kolom grid actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF97316),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isEmpty || content.isEmpty) return;

                        if (isEdit) {
                          existing.title = title;
                          existing.content = content;
                          existing.updatedAt = DateTime.now();
                        } else {
                          _notes.insert(
                            0,
                            QuickNote(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              title: title,
                              content: content,
                              updatedAt: DateTime.now(),
                            ),
                          );
                        }

                        _saveNotes();
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteNote(QuickNote note) async {
    final confirmed = await GlassmorphismModal.showConfirmModal(
      context: context,
      title: 'Hapus Catatan?',
      message: 'Apakah Anda yakin ingin menghapus catatan "${note.title}"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_outline,
    );
    if (confirmed == true) {
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      _saveNotes();
    }
  }

  void _copyNote(QuickNote note) {
    Clipboard.setData(ClipboardData(text: note.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Teks "${note.title}" disalin ke clipboard!'),
        backgroundColor: const Color(0xFF00A884),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareNote(QuickNote note) {
    Share.share(note.content, subject: note.title);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF97316))),
      );
    }

    final filtered = _notes.where((n) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Catatan Cepat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF97316),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditModal(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Cari catatan cepat...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                filled: true,
                fillColor: const Color(0xFF111B21),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final note = filtered[index];
                  return _buildNoteCard(note);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.note_alt_outlined, color: Colors.white24, size: 48),
          SizedBox(height: 12),
          Text(
            'Belum Ada Catatan',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Tekan tombol + di pojok kanan bawah untuk membuat template pesan baru.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(QuickNote note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sticky_note_2_outlined, color: Color(0xFFF97316), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
                onPressed: () => _showAddEditModal(note),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _deleteNote(note),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B141B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              note.content,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.copy, color: Colors.white70, size: 14),
                label: const Text('Salin', style: TextStyle(color: Colors.white70, fontSize: 11)),
                onPressed: () => _copyNote(note),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A884),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.share, color: Colors.white, size: 14),
                label: const Text('Bagikan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                onPressed: () => _shareNote(note),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
