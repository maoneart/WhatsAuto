import '../models/menu_node.dart';
import '../models/app_settings.dart';
import '../models/keyword_reply.dart';

class AutoReplyEngine {
  final List<MenuNode> nodes;
  final List<KeywordReply> keywordReplies;
  final AppSettings settings;
  final Map<String, String> _sessions = {}; // senderId -> 'idle', 'parent', or '<node_id>'

  AutoReplyEngine({
    required this.nodes,
    this.keywordReplies = const [],
    required this.settings,
  });

  static Map<String, String> resolveSenderAndDateTime({
    required String senderId,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();

    // 1. Bersihkan nama pengirim & tangani kontak tanpa nama / nomor telepon
    var cleanName = senderId.trim();
    if (cleanName.startsWith('~')) {
      cleanName = cleanName.substring(1).trim();
    }
    // Jika hanya nomor telepon (angka, +, spasi, minus, kurung), fallback ke 'Kak'
    final isPhone = RegExp(r'^[+0-9\s\-()]+$').hasMatch(cleanName);
    final displayName = (isPhone || cleanName.isEmpty) ? 'Kak' : cleanName;

    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : displayName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // 2. Format jam & tanggal Indonesia hari ini
    final jam = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final hari = days[current.weekday - 1];
    final tanggal = '${current.day} ${months[current.month - 1]} ${current.year}';

    return {
      'nama': displayName,
      'nama_depan': firstName,
      'nama_belakang': lastName,
      'jam': jam,
      'tanggal': tanggal,
      'hari': hari,
    };
  }

  static String applyTags(String template, {required String senderId, DateTime? now}) {
    final tags = resolveSenderAndDateTime(senderId: senderId, now: now);
    var rep = template;
    rep = rep.replaceAll(RegExp(r'\{\{nama\}\}', caseSensitive: false), tags['nama']!);
    rep = rep.replaceAll(RegExp(r'\{\{nama_depan\}\}', caseSensitive: false), tags['nama_depan']!);
    rep = rep.replaceAll(RegExp(r'\{\{nama_belakang\}\}', caseSensitive: false), tags['nama_belakang']!);
    rep = rep.replaceAll(RegExp(r'\{\{jam\}\}', caseSensitive: false), tags['jam']!);
    rep = rep.replaceAll(RegExp(r'\{\{tanggal\}\}', caseSensitive: false), tags['tanggal']!);
    rep = rep.replaceAll(RegExp(r'\{\{hari\}\}', caseSensitive: false), tags['hari']!);
    return rep;
  }

  void resetSession(String senderId) {
    _sessions[senderId] = 'idle';
  }

  String processMessage({
    required String senderId,
    required String incomingMessage,
  }) {
    final cleanMsg = incomingMessage.trim();
    final lowerMsg = cleanMsg.toLowerCase();
    final currentParent = _sessions[senderId] ?? 'idle';

    // -------------------------------------------------------------------------
    // FASE 1: Jika Pengguna Sedang Berada di Dalam Sesi Menu Aktif (Bukan Idle)
    // -------------------------------------------------------------------------
    if (currentParent != 'idle') {
      // 1. Perintah Keluar / Batal
      if (lowerMsg == 'batal' || lowerMsg == 'keluar' || lowerMsg == 'exit') {
        _sessions[senderId] = 'idle';
        return 'Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali.';
      }

      // 2. Tombol 0 (Kembali ke Menu Utama atau Keluar)
      if (cleanMsg == '0') {
        if (currentParent != 'parent') {
          _sessions[senderId] = 'parent';
          return renderMenu('parent');
        } else {
          _sessions[senderId] = 'idle';
          return 'Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali.';
        }
      }

      // 3. Ambil opsi di bawah parent saat ini
      final options = nodes.where((n) => n.parentId == currentParent && n.type == 2).toList();
      MenuNode? matchedOption;

      final int? numChoice = int.tryParse(cleanMsg);
      if (numChoice != null && numChoice >= 1 && numChoice <= options.length) {
        matchedOption = options[numChoice - 1];
      } else {
        matchedOption = options.firstWhere(
          (opt) {
            final title = opt.text.toLowerCase().trim();
            return title == lowerMsg || title.contains(lowerMsg);
          },
          orElse: () => MenuNode(id: '', text: '', parentId: '', type: 0),
        );
        if (matchedOption.id.isEmpty) matchedOption = null;
      }

      if (matchedOption != null) {
        final selectedId = matchedOption.id;
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
          // Leaf response (detail info/harga)
          return '${subPrompt.text.trim()}\n\n*(Ketik 0 untuk kembali ke menu, atau ketik "keluar")*';
        } else {
          return '${matchedOption.text.trim()}\n\n*(Ketik 0 untuk kembali ke menu, atau ketik "keluar")*';
        }
      }

      // Jika input salah saat berada di dalam menu aktif
      return '⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera:\n\n${renderMenu(currentParent)}';
    }

    // -------------------------------------------------------------------------
    // FASE 2: Sesi Idle (Pesan biasa / Pemicu Kata Kunci Baru)
    // -------------------------------------------------------------------------

    // A. Cek Balasan Kata Kunci (Keyword Replies)
    if (settings.isKeywordReplyEnabled && keywordReplies.isNotEmpty) {
      for (final rule in keywordReplies) {
        if (!rule.isEnabled) continue;
        final keywords = rule.incomingKeywords
            .split(',')
            .map((k) => k.trim().toLowerCase())
            .where((k) => k.isNotEmpty);

        bool isMatch = false;
        if (rule.isExactMatch) {
          isMatch = keywords.any((k) => lowerMsg == k);
        } else {
          isMatch = keywords.any((k) => lowerMsg.contains(k));
        }
        if (isMatch) {
          var reply = applyTags(rule.replyMessage, senderId: senderId);

          // Jika aturan ini memanggil Menu Balas -> Aktifkan sesi menu!
          if (rule.useMenuReply) {
            _sessions[senderId] = 'parent';
            final menuText = renderMenu('parent');
            return reply.trim().isEmpty ? menuText : '$reply\n\n$menuText';
          }

          if (reply.trim().isNotEmpty) {
            return reply;
          }
        }
      }
    }

    // B. Kata kunci umum pemanggil menu utama
    if (lowerMsg == 'menu' || lowerMsg == 'katalog' || lowerMsg == 'pilihan' || lowerMsg == 'bantuan') {
      _sessions[senderId] = 'parent';
      return renderMenu('parent');
    }

    // C. Pesan santai / umum di luar menu
    if (settings.onlyReplyKeywords) {
      // Diam / jangan balas apapun jika bukan kata kunci terdaftar!
      return '';
    }
    return applyTags(settings.defaultReply, senderId: senderId);
  }

  String renderMenu(String parentId) {
    final promptNode = nodes.firstWhere(
      (n) => n.parentId == parentId && n.type == 1,
      orElse: () => MenuNode(id: '', text: '', parentId: '', type: 0),
    );

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
      final cleanTitle = opt.text.trim().replaceFirst(RegExp(r'^\d+\.\s*'), '');
      buffer.writeln('${i + 1}. $cleanTitle');
    }

    buffer.writeln();
    if (parentId != 'parent') {
      buffer.writeln('0. ↩️ Kembali ke Menu Utama');
    } else {
      buffer.writeln('0. ❌ Tutup Menu');
    }

    return buffer.toString().trim();
  }
}
