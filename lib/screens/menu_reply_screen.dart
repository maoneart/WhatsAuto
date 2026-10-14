import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/menu_node.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../widgets/glassmorphism_modal.dart';
import '../widgets/tree_line_painter.dart';

class MenuReplyScreen extends StatefulWidget {
  const MenuReplyScreen({super.key});

  @override
  State<MenuReplyScreen> createState() => _MenuReplyScreenState();
}

class _MenuReplyScreenState extends State<MenuReplyScreen> {
  List<MenuNode> _allNodes = [];
  bool _isLoading = true;

  // Stack navigasi hierarki pohon (dimulai dari 'parent')
  final List<String> _navigationStack = ['parent'];

  String get _currentParentId => _navigationStack.last;

  @override
  void initState() {
    super.initState();
    _loadNodes();
  }

  Future<void> _loadNodes() async {
    setState(() => _isLoading = true);
    final nodes = await StorageService.loadMenuNodes();
    setState(() {
      _allNodes = nodes;
      _isLoading = false;
    });
  }

  Future<void> _saveCurrentNodes() async {
    await StorageService.saveMenuNodes(_allNodes);
  }

  void _navigateDown(String nodeId) {
    setState(() {
      _navigationStack.add(nodeId);
    });
  }

  bool _navigateUp() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
      });
      return true;
    }
    return false;
  }

  MenuNode? _findPromptNode(String parentId) {
    try {
      return _allNodes.firstWhere((n) => n.parentId == parentId && n.type == 1);
    } catch (_) {
      return null;
    }
  }

  List<MenuNode> _findOptionNodes(String parentId) {
    return _allNodes.where((n) => n.parentId == parentId && n.type == 2).toList();
  }

  bool _nodeHasSubmenu(String nodeId) {
    return _allNodes.any((n) => n.parentId == nodeId);
  }

  // --- Operasi CRUD Node ---
  void _editPromptDialog(MenuNode? existingPrompt) {
    final controller = TextEditingController(
      text: existingPrompt?.text ?? 'Silakan pilih satu *Nomor* atau opsi menu yang Anda inginkan:',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Pesan Sambutan / Prompt', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tulis pesan sambutan menu...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFF111B21),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newText = controller.text.trim();
                      if (newText.isNotEmpty) {
                        setState(() {
                          if (existingPrompt != null) {
                            existingPrompt.text = newText;
                          } else {
                            final newId = '${DateTime.now().millisecondsSinceEpoch % 100000}';
                            _allNodes.add(MenuNode(
                              id: newId,
                              text: newText,
                              parentId: _currentParentId,
                              type: 1,
                            ));
                          }
                        });
                        await _saveCurrentNodes();
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addNewOptionDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tambah Opsi Menu Baru', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Contoh: Cek Harga, Konsultasi, dll.',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
            filled: true,
            fillColor: const Color(0xFF111B21),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newText = controller.text.trim();
                      if (newText.isNotEmpty) {
                        final newId = '${DateTime.now().millisecondsSinceEpoch % 100000}';
                        setState(() {
                          _allNodes.add(MenuNode(
                            id: newId,
                            text: newText,
                            parentId: _currentParentId,
                            type: 2,
                          ));
                        });
                        await _saveCurrentNodes();
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editOptionDialog(MenuNode optionNode) {
    final controller = TextEditingController(text: optionNode.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Opsi Menu', style: TextStyle(color: Colors.white, fontSize: 17)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF111B21),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Batal', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      final newText = controller.text.trim();
                      if (newText.isNotEmpty) {
                        setState(() {
                          optionNode.text = newText;
                        });
                        await _saveCurrentNodes();
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A884),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteOption(MenuNode optionNode) async {
    final confirm = await GlassmorphismModal.showConfirmModal(
      context: context,
      title: 'Hapus Opsi Menu?',
      message: 'Apakah Anda yakin ingin menghapus "${optionNode.text}" beserta seluruh sub-menunya?',
      confirmText: 'Hapus',
      confirmColor: const Color(0xFFEF4444),
      icon: Icons.delete_outline,
    );

    if (confirm == true) {
      setState(() {
        // Hapus node dan anak-anaknya secara rekursif
        final toDeleteIds = <String>{optionNode.id};
        bool added = true;
        while (added) {
          added = false;
          for (final n in _allNodes) {
            if (toDeleteIds.contains(n.parentId) && !toDeleteIds.contains(n.id)) {
              toDeleteIds.add(n.id);
              added = true;
            }
          }
        }
        _allNodes.removeWhere((n) => toDeleteIds.contains(n.id));
      });
      await _saveCurrentNodes();
    }
  }

  // --- Import / Export CSV ---
  Future<void> _importCsvAction() async {
    // 1. Cek file bawaan di Download/Bug terlebih dahulu
    const quickPath = '/sdcard/Download/Bug/WhatsAuto_2026_10_14_13.csv';
    final quickFile = File(quickPath);
    if (await quickFile.exists()) {
      final confirm = await GlassmorphismModal.showConfirmModal(
        context: context,
        title: 'Impor CSV Terdeteksi',
        message: 'Ditemukan file "$quickPath" (${(await quickFile.length()) ~/ 1024} KB). Muat data ini sekarang?',
        confirmText: 'Muat Sekarang',
      );
      if (confirm == true) {
        final content = await quickFile.readAsString();
        final nodes = CsvService.parseWhatsAutoCsv(content);
        if (nodes.isNotEmpty) {
          setState(() {
            _allNodes = nodes;
            _navigationStack.clear();
            _navigationStack.add('parent');
          });
          await _saveCurrentNodes();
          if (mounted) {
            GlassmorphismModal.showAlertModal(
              context: context,
              title: 'Impor Berhasil',
              message: 'Sukses memuat ${nodes.length} nodes menu dari CSV Kaido!',
            );
          }
          return;
        }
      }
    }

    // 2. Jika tidak, buka FilePicker
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final nodes = CsvService.parseWhatsAutoCsv(content);
        if (nodes.isNotEmpty) {
          setState(() {
            _allNodes = nodes;
            _navigationStack.clear();
            _navigationStack.add('parent');
          });
          await _saveCurrentNodes();
          if (mounted) {
            GlassmorphismModal.showAlertModal(
              context: context,
              title: 'Impor Berhasil',
              message: 'Sukses memuat ${nodes.length} nodes menu!',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        GlassmorphismModal.showAlertModal(
          context: context,
          title: 'Gagal Impor',
          message: 'Error saat membaca file CSV: $e',
          iconColor: const Color(0xFFEF4444),
        );
      }
    }
  }

  Future<void> _exportCsvAction() async {
    try {
      final path = await CsvService.saveCsvToDownload(_allNodes);
      if (mounted) {
        GlassmorphismModal.showAlertModal(
          context: context,
          title: 'Ekspor Berhasil',
          message: 'File CSV berhasil diekspor ke:\n$path\n\nKompatibel 100% dengan WhatsAuto.',
        );
      }
    } catch (e) {
      if (mounted) {
        GlassmorphismModal.showAlertModal(
          context: context,
          title: 'Gagal Ekspor',
          message: 'Error saat mengekspor: $e',
          iconColor: const Color(0xFFEF4444),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00A884))),
      );
    }

    final promptNode = _findPromptNode(_currentParentId);
    final options = _findOptionNodes(_currentParentId);
    final isRoot = _currentParentId == 'parent';

    // Mencari judul parent jika sedang di dalam sub-menu
    String currentTitle = 'Menu Balas';
    if (!isRoot) {
      try {
        final p = _allNodes.firstWhere((n) => n.id == _currentParentId);
        currentTitle = p.text.trim();
      } catch (_) {}
    }

    return WillPopScope(
      onWillPop: () async {
        if (_navigateUp()) return false;
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B141B),
        appBar: AppBar(
          backgroundColor: const Color(0xFF111B21),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (!_navigateUp()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            currentTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.access_time, color: Colors.white70),
              onPressed: () {},
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: const Color(0xFF1F2C34),
              onSelected: (val) {
                if (val == 'import') _importCsvAction();
                if (val == 'export') _exportCsvAction();
                if (val == 'reset') {
                  StorageService.resetToSampleNodes().then((_) => _loadNodes());
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [
                      Icon(Icons.file_upload_outlined, color: Color(0xFF00A884), size: 20),
                      SizedBox(width: 10),
                      Text('Impor File CSV', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: Color(0xFF00A884), size: 20),
                      SizedBox(width: 10),
                      Text('Ekspor ke CSV', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.amber, size: 20),
                      SizedBox(width: 10),
                      Text('Reset ke Data Kaido', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb Navigation jika di dalam sub-menu
              if (!isRoot) ...[
                InkWell(
                  onTap: _navigateUp,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B21),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.subdirectory_arrow_left, color: Color(0xFF00A884), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Kembali ke Level Sebelumnya',
                          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Kartu Prompt Utama (Hijau Gelap Khas WhatsAuto)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF005D4B), // Warna hijau gelap WhatsAuto
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            promptNode?.text ??
                                (isRoot
                                    ? 'Ada yang *Kaido* dapat bantu untuk Anda hari ini?\n\nSilakan pilih satu *Nomor* atau opsi menu yang Anda inginkan:'
                                    : 'Silakan pilih opsi yang tersedia:'),
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF1F2C34),
                          onSelected: (v) {
                            if (v == 'edit') _editPromptDialog(promptNode);
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Pesan Ini', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Daftar Opsi Anak dengan Garis Pohon Hierarki
              const SizedBox(height: 8),
              for (int i = 0; i < options.length; i++) ...[
                _buildOptionTreeItem(
                  option: options[i],
                  index: i,
                  isLast: i == options.length - 1 && options.length > 0,
                ),
                const SizedBox(height: 8),
              ],

              // Tombol "TAMBAHKAN DAFTAR" di Bawah Garis Pohon
              TreeBranchDecoration(
                isLast: true,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  child: OutlinedButton(
                    onPressed: _addNewOptionDialog,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF111B21),
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'TAMBAHKAN DAFTAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTreeItem({
    required MenuNode option,
    required int index,
    required bool isLast,
  }) {
    final hasSubmenu = _nodeHasSubmenu(option.id);

    return TreeBranchDecoration(
      isLast: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Masuk ke sub-menu anak
            _navigateDown(option.id);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF005D4B), // Warna hijau gelap WhatsAuto
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${option.text.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasSubmenu ? 'SUBMENU' : 'PESAN JAWABAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF1F2C34),
                  onSelected: (v) {
                    if (v == 'open') _navigateDown(option.id);
                    if (v == 'edit') _editOptionDialog(option);
                    if (v == 'delete') _deleteOption(option);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Buka Sub-menu', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Judul', style: TextStyle(color: Colors.white)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus', style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
