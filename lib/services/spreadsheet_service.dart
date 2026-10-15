import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import '../models/spreadsheet_model.dart';

class SpreadsheetService {
  /// Mengekstrak link export CSV dari berbagai format input Google Sheet:
  /// - Full URL: https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms/edit...
  /// - Published URL: https://docs.google.com/spreadsheets/d/e/2PACX-.../pub?output=csv
  /// - ID saja: 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms
  /// - Custom CSV link publik langsung
  static String resolveCsvExportUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // Jika sudah berupa link export CSV langsung
    if (trimmed.contains('export?format=csv') || trimmed.contains('output=csv')) {
      return trimmed;
    }

    // Deteksi ID dari format https://docs.google.com/spreadsheets/d/{ID}/...
    final regex = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)');
    final match = regex.firstMatch(trimmed);
    if (match != null && match.groupCount >= 1) {
      final sheetId = match.group(1);
      // Cek apakah ada parameter gid
      final gidRegex = RegExp(r'[#&?]gid=([0-9]+)');
      final gidMatch = gidRegex.firstMatch(trimmed);
      final gidParam = (gidMatch != null && gidMatch.groupCount >= 1)
          ? '&gid=${gidMatch.group(1)}'
          : '';
      return 'https://docs.google.com/spreadsheets/d/$sheetId/export?format=csv$gidParam';
    }

    // Jika hanya berupa alphanumeric Sheet ID tanpa URL
    if (RegExp(r'^[a-zA-Z0-9-_]{20,}$').hasMatch(trimmed)) {
      return 'https://docs.google.com/spreadsheets/d/$trimmed/export?format=csv';
    }

    // Default gunakan input langsung
    return trimmed;
  }

  /// Sinkronisasi data dari Google Sheet CSV ke List<SheetReplyItem>
  static Future<List<SheetReplyItem>> fetchSheetData(String urlOrId) async {
    final exportUrl = resolveCsvExportUrl(urlOrId);
    if (exportUrl.isEmpty) {
      throw Exception('Link atau ID Google Spreadsheet tidak boleh kosong.');
    }

    final uri = Uri.parse(exportUrl);
    final response = await http.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Koneksi ke Google Spreadsheet batas waktu habis (timeout).'),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        throw Exception('Spreadsheet tidak ditemukan (404). Periksa kembali Link atau ID Sheet.');
      } else if (response.statusCode == 403 || response.statusCode == 401) {
        throw Exception(
            'Akses ditolak. Pastikan akses Google Sheet diubah menjadi "Siapa saja yang memiliki link dapat melihat" (Anyone with the link).');
      } else {
        throw Exception('Gagal mengunduh spreadsheet (Kode HTTP ${response.statusCode}).');
      }
    }

    final csvContent = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (csvContent.trim().isEmpty) {
      throw Exception('Data spreadsheet kosong.');
    }

    const converter = CsvToListConverter(eol: '\n', shouldParseNumbers: false);
    final rows = converter.convert(csvContent);

    if (rows.isEmpty) {
      throw Exception('Tidak ada baris data yang ditemukan di spreadsheet.');
    }

    final List<SheetReplyItem> items = [];
    int startIndex = 0;

    // Deteksi apakah baris pertama adalah Header tabel
    if (rows.isNotEmpty) {
      final firstRow = rows.first.map((e) => e.toString().toLowerCase().trim()).toList();
      final isHeader = firstRow.any((cell) =>
          cell.contains('kata kunci') ||
          cell.contains('keyword') ||
          cell.contains('incoming') ||
          cell.contains('pesan masuk') ||
          cell.contains('jawaban') ||
          cell.contains('balasan') ||
          cell.contains('reply'));
      if (isHeader) {
        startIndex = 1;
      }
    }

    for (int i = startIndex; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final colA = row.isNotEmpty ? row[0].toString().trim() : '';
      final colB = row.length > 1 ? row[1].toString().trim() : '';
      final colC = row.length > 2 ? row[2].toString().trim() : '';

      // Skip baris jika kolom keyword kosong
      if (colA.isEmpty) continue;

      // Match option: 0 = Exact, 1 = Contains
      int matchOption = 1;
      if (colC.toLowerCase() == '0' ||
          colC.toLowerCase() == 'exact' ||
          colC.toLowerCase() == 'persis' ||
          colC.toLowerCase() == 'tepat') {
        matchOption = 0;
      } else if (colC.toLowerCase() == '1' ||
          colC.toLowerCase() == 'contains' ||
          colC.toLowerCase() == 'mengandung') {
        matchOption = 1;
      }

      items.add(SheetReplyItem(
        keyword: colA,
        reply: colB,
        matchOption: matchOption,
      ));
    }

    if (items.isEmpty) {
      throw Exception('Spreadsheet berhasil dibaca, namun tidak ditemukan pasangan Kolom A (Kata Kunci) dan Kolom B (Balasan).');
    }

    return items;
  }
}
