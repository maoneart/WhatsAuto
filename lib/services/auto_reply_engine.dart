import '../models/menu_node.dart';
import '../models/app_settings.dart';

class AutoReplyEngine {
  final List<MenuNode> nodes;
  final AppSettings settings;
  final Map<String, String> _sessions = {}; // senderId -> current parentId

  AutoReplyEngine({
    required this.nodes,
    required this.settings,
  });

  void resetSession(String senderId) {
    _sessions[senderId] = 'parent';
  }

  String processMessage({
    required String senderId,
    required String incomingMessage,
  }) {
    final cleanMsg = incomingMessage.trim();
    final currentParent = _sessions[senderId] ?? 'parent';

    // 1. Keyword reset / kembali ke menu awal
    if (cleanMsg.toLowerCase() == 'menu' ||
        cleanMsg.toLowerCase() == 'halo' ||
        cleanMsg.toLowerCase() == 'hi' ||
        cleanMsg.toLowerCase() == 'batal' ||
        cleanMsg == '0') {
      _sessions[senderId] = 'parent';
      return renderMenu('parent');
    }

    // 2. Ambil semua opsi yang berada di bawah currentParent
    final options = nodes.where((n) => n.parentId == currentParent && n.type == 2).toList();

    MenuNode? matchedOption;

    // A. Cek kecocokan berdasarkan nomor urut (1, 2, 3...)
    final int? numChoice = int.tryParse(cleanMsg);
    if (numChoice != null && numChoice >= 1 && numChoice <= options.length) {
      matchedOption = options[numChoice - 1];
    } else {
      // B. Cek kecocokan berdasarkan teks judul opsi
      matchedOption = options.firstWhere(
        (opt) {
          final title = opt.text.toLowerCase().trim();
          final q = cleanMsg.toLowerCase();
          return title == q || title.contains(q);
        },
        orElse: () => MenuNode(id: '', text: '', parentId: '', type: 0),
      );
      if (matchedOption.id.isEmpty) matchedOption = null;
    }

    if (matchedOption != null) {
      final selectedId = matchedOption.id;

      // Cek apakah node yang dipilih memiliki opsi anak (submenu)
      final subOptions = nodes.where((n) => n.parentId == selectedId && n.type == 2).toList();
      final subPrompt = nodes.firstWhere(
        (n) => n.parentId == selectedId && n.type == 1,
        orElse: () => MenuNode(id: '', text: '', parentId: '', type: 0),
      );

      if (subOptions.isNotEmpty) {
        // Masuk ke level submenu berikutnya
        _sessions[senderId] = selectedId;
        return renderMenu(selectedId);
      } else if (subPrompt.id.isNotEmpty) {
        // Leaf response (misal: Spesifikasi HP / Harga Cicilan / Maaf Belum Tersedia)
        _sessions[senderId] = 'parent'; // Reset agar interaksi berikutnya kembali ke menu utama
        return '${subPrompt.text.trim()}\n\n*(Ketik 0 atau "menu" untuk kembali ke menu utama)*';
      } else {
        // Jika tidak ada sub-prompt, tampilkan teks opsi itu sendiri
        _sessions[senderId] = 'parent';
        return '${matchedOption.text.trim()}\n\n*(Ketik 0 atau "menu" untuk kembali ke menu utama)*';
      }
    }

    // 3. Jika input tidak cocok
    if (currentParent == 'parent') {
      // Jika di root dan tidak ada kata kunci menu yang cocok, tampilkan default reply atau menu root
      return renderMenu('parent');
    } else {
      // Jika di dalam submenu tapi input salah, beri tahu dan tampilkan menu saat ini
      return '⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera di bawah:\n\n${renderMenu(currentParent)}';
    }
  }

  String renderMenu(String parentId) {
    // 1. Ambil prompt teks untuk level ini
    final promptNode = nodes.firstWhere(
      (n) => n.parentId == parentId && n.type == 1,
      orElse: () => MenuNode(id: '', text: '', parentId: '', type: 0),
    );

    // 2. Ambil seluruh opsi untuk level ini
    final options = nodes.where((n) => n.parentId == parentId && n.type == 2).toList();

    final buffer = StringBuffer();

    if (promptNode.id.isNotEmpty) {
      buffer.writeln(promptNode.text.trim());
      buffer.writeln();
    } else if (parentId == 'parent') {
      buffer.writeln('Silakan pilih salah satu menu di bawah ini:');
      buffer.writeln();
    }

    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      // Bersihkan angka bawaan di awal jika ada agar tidak double numbering
      final cleanTitle = opt.text.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '');
      buffer.writeln('${i + 1}. $cleanTitle');
    }

    if (parentId != 'parent') {
      buffer.writeln();
      buffer.writeln('0. ↩️ Kembali ke Menu Utama');
    }

    return buffer.toString().trim();
  }
}
