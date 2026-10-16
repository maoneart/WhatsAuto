import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/menu_node.dart';
import '../models/menu_project.dart';
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
  List<MenuProject> _projects = [];
  MenuProject? _currentProject;
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
    final projects = await StorageService.loadMenuProjects();
    final activeId = await StorageService.getActiveProjectId();
    final activeProject = projects.firstWhere(
      (p) => p.id == activeId,
      orElse: () => projects.first,
    );
    setState(() {
      _projects = projects;
      _currentProject = activeProject;
      _allNodes = List<MenuNode>.from(activeProject.nodes);
      _navigationStack.clear();
      _navigationStack.add('parent');
      _isLoading = false;
    });
  }

  Future<void> _saveCurrentNodes() async {
    if (_currentProject != null) {
      _currentProject!.nodes = List<MenuNode>.from(_allNodes);
      _currentProject!.updatedAt = DateTime.now();
      await StorageService.saveProject(_currentProject!);
    } else {
      await StorageService.saveMenuNodes(_allNodes);
    }
  }

  Future<void> _switchProject(String projectId) async {
    await _saveCurrentNodes();
    await StorageService.setActiveProjectId(projectId);
    await _loadNodes();
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

  // =========================================================================
  // Dialog & Sheet Manajemen Multi-Proyek Menu Balas
  // =========================================================================
  void _showProjectSelectorSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111B21),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kelola Proyek Menu Balas',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Beralih atau buat katalog menu untuk bisnis berbeda',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF00A884), size: 26),
                          tooltip: 'Buat Proyek Baru',
                          onPressed: () {
                            Navigator.pop(ctx);
                            _createNewProjectDialog();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = _projects[index];
                          final isActive = p.id == _currentProject?.id;

                          return Container(
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF005D4B).withOpacity(0.35) : const Color(0xFF1F2C34),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? const Color(0xFF00A884) : Colors.white.withOpacity(0.08),
                                width: isActive ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                isActive ? Icons.check_circle : Icons.folder_outlined,
                                color: isActive ? const Color(0xFF00A884) : Colors.white54,
                              ),
                              title: Text(
                                p.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${p.nodes.length} menu • ${p.description.isNotEmpty ? p.description : "Katalog Menu"}',
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 18),
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      _renameProjectDialog(p);
                                    },
                                    tooltip: 'Edit Nama Proyek',
                                  ),
                                  if (_projects.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteProjectDialog(p);
                                      },
                                      tooltip: 'Hapus Proyek',
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _switchProject(p.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00A884),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Buat Proyek Menu Baru', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _createNewProjectDialog();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _createNewProjectDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    bool copyCurrent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1F2C34),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.create_new_folder_outlined, color: Color(0xFF00A884), size: 22),
                SizedBox(width: 10),
                Text('Proyek Menu Baru', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Proyek (misal: Klinik, Makanan, Toko)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Klinik Pratama Sehat',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                      filled: true,
                      fillColor: const Color(0xFF111B21),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Deskripsi Singkat (Opsional)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Layanan Poli & Jadwal Dokter',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                      filled: true,
                      fillColor: const Color(0xFF111B21),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: copyCurrent,
                    activeColor: const Color(0xFF00A884),
                    title: const Text('Salin menu dari proyek saat ini', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    onChanged: (v) => setDlgState(() => copyCurrent = v ?? false),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A884),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nama proyek tidak boleh kosong!')),
                          );
                          return;
                        }

                        List<MenuNode> initialNodes;
                        if (copyCurrent && _allNodes.isNotEmpty) {
                          initialNodes = _allNodes.map((n) => n.copyWith()).toList();
                        } else {
                          initialNodes = [
                            MenuNode(
                              id: '1',
                              text: 'Halo! Selamat datang di $name.\n\nSilakan pilih nomor layanan:',
                              parentId: 'parent',
                              type: 1,
                            ),
                          ];
                        }

                        final newProj = MenuProject(
                          id: 'proj_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          description: descController.text.trim(),
                          nodes: initialNodes,
                        );

                        await StorageService.saveProject(newProj);
                        await StorageService.setActiveProjectId(newProj.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                        await _loadNodes();

                        if (mounted) {
                          GlassmorphismModal.showAlertModal(
                            context: context,
                            title: 'Proyek Dibuat',
                            message: 'Proyek "$name" berhasil dibuat dan aktif sebagai Menu Balas.',
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _renameProjectDialog(MenuProject project) {
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(text: project.description);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2C34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Proyek Menu', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nama Proyek', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111B21),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Deskripsi Singkat', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: descController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF111B21),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    project.name = name;
                    project.description = descController.text.trim();
                    project.updatedAt = DateTime.now();
                    await StorageService.saveProject(project);
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadNodes();
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteProjectDialog(MenuProject project) {
    GlassmorphismModal.showConfirmModal(
      context: context,
      title: 'Hapus Proyek?',
      message: 'Apakah Anda yakin ingin menghapus proyek "${project.name}" beserta ${project.nodes.length} menu di dalamnya?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDanger: true,
      onConfirm: () async {
        final success = await StorageService.deleteProject(project.id);
        if (success) {
          await _loadNodes();
          if (mounted) {
            GlassmorphismModal.showAlertModal(
              context: context,
              title: 'Proyek Dihapus',
              message: 'Proyek "${project.name}" berhasil dihapus.',
            );
          }
        }
      },
    );
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
              icon: const Icon(Icons.folder_copy_outlined, color: Color(0xFF00A884)),
              tooltip: 'Kelola Proyek Menu',
              onPressed: _showProjectSelectorSheet,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              color: const Color(0xFF1F2C34),
              onSelected: (val) {
                if (val == 'projects') _showProjectSelectorSheet();
                if (val == 'new_project') _createNewProjectDialog();
                if (val == 'import') _importCsvAction();
                if (val == 'export') _exportCsvAction();
                if (val == 'reset') {
                  StorageService.resetToSampleNodes().then((_) => _loadNodes());
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'projects',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open, color: Color(0xFF00A884), size: 20),
                      SizedBox(width: 10),
                      Text('Daftar Proyek Menu', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'new_project',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: Color(0xFF00A884), size: 20),
                      SizedBox(width: 10),
                      Text('Buat Proyek Baru', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
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
              // Switcher Proyek Menu Balas (Aktif di Root Level)
              if (isRoot) ...[
                InkWell(
                  onTap: _showProjectSelectorSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B21),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00A884).withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_tree, color: Color(0xFF00A884), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'PROYEK MENU BALAS',
                                    style: TextStyle(
                                      color: Color(0xFF00A884),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${_projects.length} Proyek',
                                      style: const TextStyle(color: Colors.white70, fontSize: 9),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentProject?.name ?? 'Proyek Menu Utama',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.unfold_more, color: Colors.white54, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

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
