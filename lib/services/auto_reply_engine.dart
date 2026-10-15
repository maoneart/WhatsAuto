import '../models/menu_node.dart';
import '../models/app_settings.dart';
import '../models/keyword_reply.dart';
import '../models/spreadsheet_model.dart';

class AutoReplyEngine {
  final List<MenuNode> nodes;
  final List<KeywordReply> keywordReplies;
  final List<SheetReplyItem> sheetItems;
  final bool isSheetEnabled;
  final AppSettings settings;
  final Map<String, String> _sessions = {}; // senderId -> 'idle', 'parent', or '<node_id>'

  AutoReplyEngine({
    required this.nodes,
    this.keywordReplies = const [],
    this.sheetItems = const [],
    this.isSheetEnabled = false,
    required this.settings,
  });

  static Map<String, String> resolveSenderAndDateTime({
    required String senderId,
    DateTime? now,
    String? incomingMessage,
  }) {
    final current = now ?? DateTime.now();

    // 1. Bersihkan karakter tersembunyi Unicode WhatsApp (\u200e, \u2068, \u2069)
    var cleanName = senderId.replaceAll(RegExp(r'[\u200e\u2068\u2069]'), '').trim();
    if (cleanName.startsWith('~')) {
      cleanName = cleanName.substring(1).trim();
    }

    // Ekstraksi nama jika format grup WhatsApp ("Pengirim @ Grup" atau "Grup: Pengirim")
    if (cleanName.contains('@') && cleanName.indexOf('@') > 1) {
      cleanName = cleanName.substring(0, cleanName.indexOf('@') - 1).trim();
    } else if (cleanName.contains(':') && !cleanName.startsWith('+')) {
      cleanName = cleanName.substring(cleanName.lastIndexOf(':') + 1).trim();
    }

    // Jika hanya nomor telepon (angka, +, spasi, minus, kurung), fallback ke 'Kak'
    final isPhone = RegExp(r'^[+0-9\s\-()]+$').hasMatch(cleanName);
    final displayName = (isPhone || cleanName.isEmpty) ? 'Kak' : cleanName;

    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.isNotEmpty ? parts.first : displayName;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    // 2. Format jam & tanggal Indonesia hari ini (Persis WhatsAuto dd-MM-yyyy / format lokal)
    final jam = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final hari = days[current.weekday - 1];
    final tanggal = '${current.day} ${months[current.month - 1]} ${current.year}';
    final tanggalSingkat = '${current.day.toString().padLeft(2, '0')}-${current.month.toString().padLeft(2, '0')}-${current.year}';

    return {
      'nama': displayName,
      'nama_depan': firstName,
      'nama_belakang': lastName,
      'jam': jam,
      'tanggal': tanggal,
      'tanggal_singkat': tanggalSingkat,
      'hari': hari,
      'pesan': incomingMessage ?? '',
    };
  }

  static String applyTags(
    String template, {
    required String senderId,
    DateTime? now,
    String? incomingMessage,
  }) {
    final tags = resolveSenderAndDateTime(
      senderId: senderId,
      now: now,
      incomingMessage: incomingMessage,
    );
    var rep = template;

    // Dukung kurung kurawal ganda {{...}} MAUPUN kurung kurawal tunggal {...} persis WhatsAuto asli
    rep = rep.replaceAll(RegExp(r'\{\{?nama\}?\}', caseSensitive: false), tags['nama']!);
    rep = rep.replaceAll(RegExp(r'\{\{?name\}?\}', caseSensitive: false), tags['nama']!);

    rep = rep.replaceAll(RegExp(r'\{\{?nama_depan\}?\}', caseSensitive: false), tags['nama_depan']!);
    rep = rep.replaceAll(RegExp(r'\{\{?nama depan\}?\}', caseSensitive: false), tags['nama_depan']!);
    rep = rep.replaceAll(RegExp(r'\{\{?first_name\}?\}', caseSensitive: false), tags['nama_depan']!);
    rep = rep.replaceAll(RegExp(r'\{\{?first name\}?\}', caseSensitive: false), tags['nama_depan']!);

    rep = rep.replaceAll(RegExp(r'\{\{?nama_belakang\}?\}', caseSensitive: false), tags['nama_belakang']!);
    rep = rep.replaceAll(RegExp(r'\{\{?nama belakang\}?\}', caseSensitive: false), tags['nama_belakang']!);
    rep = rep.replaceAll(RegExp(r'\{\{?last_name\}?\}', caseSensitive: false), tags['nama_belakang']!);
    rep = rep.replaceAll(RegExp(r'\{\{?last name\}?\}', caseSensitive: false), tags['nama_belakang']!);

    rep = rep.replaceAll(RegExp(r'\{\{?jam\}?\}', caseSensitive: false), tags['jam']!);
    rep = rep.replaceAll(RegExp(r'\{\{?time\}?\}', caseSensitive: false), tags['jam']!);

    rep = rep.replaceAll(RegExp(r'\{\{?tanggal\}?\}', caseSensitive: false), tags['tanggal']!);
    rep = rep.replaceAll(RegExp(r'\{\{?date\}?\}', caseSensitive: false), tags['tanggal']!);

    rep = rep.replaceAll(RegExp(r'\{\{?hari\}?\}', caseSensitive: false), tags['hari']!);

    rep = rep.replaceAll(RegExp(r'\{\{?pesan\}?\}', caseSensitive: false), tags['pesan']!);
    rep = rep.replaceAll(RegExp(r'\{\{?message\}?\}', caseSensitive: false), tags['pesan']!);

    return rep;
  }

  void resetSession(String senderId) {
    _sessions[senderId] = 'idle';
  }

  String wrapHeaderFooter(String reply) {
    if (reply.trim().isEmpty) return reply;
    var res = reply;
    if (settings.enableReplyHeader && settings.replyHeaderText.trim().isNotEmpty) {
      res = '${settings.replyHeaderText.trim()}\n$res';
    }
    if (settings.enableReplyFooter && settings.replyFooterText.trim().isNotEmpty) {
      res = '$res\n${settings.replyFooterText.trim()}';
    }
    return res;
  }

  String processMessage({
    required String senderId,
    required String incomingMessage,
  }) {
    final rawReply = _computeRawReply(senderId: senderId, incomingMessage: incomingMessage);
    if (rawReply.trim().isEmpty) return '';
    return wrapHeaderFooter(rawReply);
  }

  String _computeRawReply({
    required String senderId,
    required String incomingMessage,
  }) {
    // Bersihkan karakter Unicode tersembunyi WhatsApp (\u200e, \u2068, \u2069)
    final cleanMsg = incomingMessage.replaceAll(RegExp(r'[\u200e\u2068\u2069]'), '').trim();
    final lowerMsg = cleanMsg.toLowerCase();
    // Normalisasi tanda baca persis WhatsAuto: buang [?!.\n]
    final normalizedMsg = cleanMsg.replaceAll(RegExp(r'[?!.\n]'), '').trim().toLowerCase();
    final currentParent = _sessions[senderId] ?? 'idle';

    // =========================================================================
    // FASE 1: Cek Balasan Kata Kunci (Keyword Replies) TERLEBIH DAHULU
    // Persis WhatsAuto resmi: kata kunci selalu memiliki prioritas lebih tinggi daripada menu
    // =========================================================================
    if (settings.isKeywordReplyEnabled && keywordReplies.isNotEmpty) {
      final paddedMsg = " $normalizedMsg ";

      // 1. Prioritas 1: Exact Match (Cocokan Tepat) untuk kata kunci spesifik (bukan '*')
      for (final rule in keywordReplies) {
        if (!rule.isEnabled || !rule.isExactMatch) continue;
        final keywords = rule.incomingKeywords.split(',');
        final isMatch = keywords.any((k) {
          final cleanKw = k.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase();
          return cleanKw.isNotEmpty && cleanKw != '*' && cleanKw == normalizedMsg;
        });

        if (isMatch) {
          var reply = applyTags(rule.replyMessage, senderId: senderId, incomingMessage: cleanMsg);

          if (rule.useMenuReply) {
            _sessions[senderId] = 'parent';
            final menuText = renderMenu('parent');
            return reply.trim().isEmpty ? menuText : '$reply\n\n$menuText';
          }
          if (rule.useWebhook && reply.trim().isEmpty) {
            reply = '🌐 [Pesan diproses via Web Server]';
          }
          if (rule.useAiReply && reply.trim().isEmpty) {
            reply = '🤖 [Balasan otomatis oleh AI]';
          }
          // Reset sesi menu menjadi idle
          _sessions[senderId] = 'idle';
          if (reply.trim().isNotEmpty) {
            return reply;
          }
        }
      }

      // 2. Prioritas 2: Contains Match (Mengandung) untuk kata kunci spesifik (bukan '*')
      for (final rule in keywordReplies) {
        if (!rule.isEnabled || rule.isExactMatch) continue;
        final keywords = rule.incomingKeywords.split(',');
        final isMatch = keywords.any((k) {
          final cleanKw = k.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase();
          if (cleanKw.isEmpty || cleanKw == '*') return false;
          // Word boundary check persis WhatsAuto: cek dengan spasi atau substring
          return paddedMsg.contains(" $cleanKw ") || normalizedMsg.contains(cleanKw);
        });

        if (isMatch) {
          var reply = applyTags(rule.replyMessage, senderId: senderId, incomingMessage: cleanMsg);

          if (rule.useMenuReply) {
            _sessions[senderId] = 'parent';
            final menuText = renderMenu('parent');
            return reply.trim().isEmpty ? menuText : '$reply\n\n$menuText';
          }
          if (rule.useWebhook && reply.trim().isEmpty) {
            reply = '🌐 [Pesan diproses via Web Server]';
          }
          if (rule.useAiReply && reply.trim().isEmpty) {
            reply = '🤖 [Balasan otomatis oleh AI]';
          }
          // Reset sesi menu menjadi idle
          _sessions[senderId] = 'idle';
          if (reply.trim().isNotEmpty) {
            return reply;
          }
        }
      }
    }

    // =========================================================================
    // FASE 2: Sesi Menu Aktif (Hanya jika TIDAK ADA kata kunci yang cocok)
    // =========================================================================
    if (currentParent != 'idle') {
      // 1. Perintah Keluar / Batal
      if (normalizedMsg == 'batal' || normalizedMsg == 'keluar' || normalizedMsg == 'exit') {
        _sessions[senderId] = 'idle';
        return 'Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali.';
      }

      // 2. Tombol 0 (Kembali ke Menu Utama atau Keluar)
      if (normalizedMsg == '0') {
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
      final previousMenuNum = options.length + 1; // Nomor untuk 'Menu Sebelumnya' persis WhatsAuto

      // Cek apakah user memilih tombol 'Menu Sebelumnya' (angka options.length + 1 atau teks 'kembali')
      final int? numChoice = int.tryParse(normalizedMsg);
      if (numChoice == previousMenuNum || normalizedMsg == 'kembali' || normalizedMsg == 'back') {
        if (currentParent != 'parent') {
          // Cari parent dari currentParent
          final currentNode = nodes.firstWhere(
            (n) => n.id == currentParent,
            orElse: () => MenuNode(id: '', text: '', parentId: 'parent', type: 0),
          );
          final grandParent = currentNode.parentId.isEmpty ? 'parent' : currentNode.parentId;
          _sessions[senderId] = grandParent;
          return renderMenu(grandParent);
        } else {
          _sessions[senderId] = 'idle';
          return 'Anda telah keluar dari menu interaktif. Ketik *menu* kapan saja untuk membukanya kembali.';
        }
      }

      MenuNode? matchedOption;
      if (numChoice != null && numChoice >= 1 && numChoice <= options.length) {
        matchedOption = options[numChoice - 1];
      } else {
        matchedOption = options.firstWhere(
          (opt) {
            final title = opt.text.replaceAll(RegExp(r'[?!.\n]'), '').toLowerCase().trim();
            return title == normalizedMsg || title.contains(normalizedMsg);
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
          // Leaf response (detail info/harga) -> reset sesi persis WhatsAuto e == 1
          _sessions[senderId] = 'idle';
          final renderedLeaf = applyTags(subPrompt.text.trim(), senderId: senderId, incomingMessage: cleanMsg);
          return '$renderedLeaf\n\n*(Sesi menu selesai. Ketik "menu" untuk membuka kembali)*';
        } else {
          _sessions[senderId] = 'idle';
          final renderedLeaf = applyTags(matchedOption.text.trim(), senderId: senderId, incomingMessage: cleanMsg);
          return '$renderedLeaf\n\n*(Sesi menu selesai. Ketik "menu" untuk membuka kembali)*';
        }
      }

      // Jika input salah saat berada di dalam menu aktif
      return '⚠️ *Pilihan tidak ditemukan.*\nSilakan balas dengan *Nomor* opsi yang tertera:\n\n${renderMenu(currentParent)}';
    }

    // B. Cek Balasan Google Spreadsheet (Katalog Harga / FAQ dari Lembar Kerja)
    if (isSheetEnabled && sheetItems.isNotEmpty) {
      final paddedMsg = " $normalizedMsg ";
      String? wildcardReply;

      // 1. Exact Match di Sheet
      for (final item in sheetItems) {
        final rawKw = item.keyword.trim();
        if (rawKw == '*') {
          wildcardReply = item.reply;
          continue;
        }
        if (item.matchOption != 0) continue;

        final kwList = rawKw.split(',').map((e) => e.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase()).where((k) => k.isNotEmpty);
        if (kwList.any((kw) => kw == normalizedMsg)) {
          final reply = applyTags(item.reply, senderId: senderId, incomingMessage: cleanMsg);
          if (reply.trim().isNotEmpty) return reply;
        }
      }

      // 2. Contains Match di Sheet
      for (final item in sheetItems) {
        final rawKw = item.keyword.trim();
        if (rawKw == '*') {
          wildcardReply = item.reply;
          continue;
        }
        if (item.matchOption != 1) continue;

        final kwList = rawKw.split(',').map((e) => e.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase()).where((k) => k.isNotEmpty);
        if (kwList.any((kw) => paddedMsg.contains(" $kw ") || normalizedMsg.contains(kw))) {
          final reply = applyTags(item.reply, senderId: senderId, incomingMessage: cleanMsg);
          if (reply.trim().isNotEmpty) return reply;
        }
      }

      // 3. Fallback Wildcard (*) dari Sheet (balas semua jika tidak ada kata kunci spesifik yang cocok)
      if (wildcardReply != null && wildcardReply.trim().isNotEmpty) {
        final reply = applyTags(wildcardReply, senderId: senderId, incomingMessage: cleanMsg);
        if (reply.trim().isNotEmpty) return reply;
      }
    }

    // C. Wildcard Catch-All (*) dari Balasan Kata Kunci (Membalas SEMUA pesan yang masuk)
    if (settings.isKeywordReplyEnabled && keywordReplies.isNotEmpty) {
      final wildcardRule = keywordReplies.firstWhere(
        (r) => r.isEnabled && r.incomingKeywords.split(',').any((k) => k.trim() == '*'),
        orElse: () => KeywordReply(id: '', incomingKeywords: '', replyMessage: ''),
      );

      if (wildcardRule.id.isNotEmpty) {
        var reply = applyTags(wildcardRule.replyMessage, senderId: senderId, incomingMessage: cleanMsg);
        if (wildcardRule.useMenuReply) {
          _sessions[senderId] = 'parent';
          final menuText = renderMenu('parent');
          return reply.trim().isEmpty ? menuText : '$reply\n\n$menuText';
        }
        if (wildcardRule.useWebhook && reply.trim().isEmpty) {
          reply = '🌐 [Pesan diproses via Web Server]';
        }
        if (wildcardRule.useAiReply && reply.trim().isEmpty) {
          reply = '🤖 [Balasan otomatis oleh AI]';
        }
        _sessions[senderId] = 'idle';
        if (reply.trim().isNotEmpty) {
          return reply;
        }
      }
    }

    // D. Kata kunci umum pemanggil menu utama
    if (normalizedMsg == 'menu' || normalizedMsg == 'katalog' || normalizedMsg == 'pilihan' || normalizedMsg == 'bantuan') {
      _sessions[senderId] = 'parent';
      return renderMenu('parent');
    }

    // C. Pesan santai / umum di luar menu
    if (settings.onlyReplyKeywords) {
      // Diam / jangan balas apapun jika bukan kata kunci terdaftar!
      return '';
    }
    return applyTags(settings.defaultReply, senderId: senderId, incomingMessage: cleanMsg);
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
      // Persis WhatsAuto: opsi N untuk Previous Menu, dan 0 untuk Main Menu
      buffer.writeln('${options.length + 1}. ↩️ Menu Sebelumnya');
      buffer.writeln('0. 🏠 Kembali ke Menu Utama');
    } else {
      buffer.writeln('0. ❌ Tutup Menu');
    }

    return buffer.toString().trim();
  }
}
