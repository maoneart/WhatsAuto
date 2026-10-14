import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import '../models/menu_node.dart';

class CsvService {
  /// Membaca string CSV format WhatsAuto menjadi list of MenuNode
  static List<MenuNode> parseWhatsAutoCsv(String csvContent) {
    if (csvContent.trim().isEmpty) return [];

    // Parse CSV dengan dukungan multiline teks dan tanda kutip
    final List<List<dynamic>> rows = const CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    ).convert(csvContent);

    final List<MenuNode> nodes = [];
    for (final row in rows) {
      if (row.length >= 4) {
        final id = row[0]?.toString().trim() ?? '';
        final text = row[1]?.toString() ?? '';
        final parentId = row[2]?.toString().trim() ?? 'parent';
        final type = int.tryParse(row[3]?.toString().trim() ?? '2') ?? 2;

        if (id.isNotEmpty) {
          nodes.add(MenuNode(
            id: id,
            text: text,
            parentId: parentId,
            type: type,
          ));
        }
      }
    }
    return nodes;
  }

  /// Mengonversi list of MenuNode menjadi string CSV format WhatsAuto yang 100% kompatibel
  static String exportToWhatsAutoCsv(List<MenuNode> nodes) {
    final List<List<dynamic>> rows = nodes.map((n) => n.toCsvRow()).toList();
    return const ListToCsvConverter(
      eol: '\n',
      quoteMode: QuoteMode.always,
    ).convert(rows);
  }

  /// Memuat sampel CSV bawaan Kaido dari assets jika database lokal masih kosong
  static Future<List<MenuNode>> loadDefaultSampleCsv() async {
    try {
      final raw = await rootBundle.loadString('assets/sample_menu.csv');
      return parseWhatsAutoCsv(raw);
    } catch (e) {
      print('Load default sample CSV error: $e');
      return [];
    }
  }

  /// Menyimpan CSV ke file download
  static Future<String> saveCsvToDownload(List<MenuNode> nodes) async {
    final csvString = exportToWhatsAutoCsv(nodes);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '/sdcard/Download/WhatsAuto_Menu_$timestamp.csv';
    final file = File(targetPath);
    await file.writeAsString(csvString, encoding: utf8);
    return targetPath;
  }
}
