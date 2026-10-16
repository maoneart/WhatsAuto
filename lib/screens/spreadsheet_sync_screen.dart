import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/spreadsheet_model.dart';
import '../services/storage_service.dart';
import '../services/spreadsheet_service.dart';
import '../widgets/glassmorphism_modal.dart';

class SpreadsheetSyncScreen extends StatefulWidget {
  const SpreadsheetSyncScreen({super.key});

  @override
  State<SpreadsheetSyncScreen> createState() => _SpreadsheetSyncScreenState();
}

class _SpreadsheetSyncScreenState extends State<SpreadsheetSyncScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _testKeywordController = TextEditingController();

  SpreadsheetConfig _config = SpreadsheetConfig();
  bool _isLoading = true;
  bool _isSyncing = false;
  String _searchQuery = '';
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _testKeywordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final cfg = await StorageService.loadSpreadsheetConfig();
    setState(() {
      _config = cfg;
      _urlController.text = cfg.sheetUrl;
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    _config.sheetUrl = _urlController.text.trim();
    await StorageService.saveSpreadsheetConfig(_config);
  }

  Future<void> _syncSheet() async {
    final inputUrl = _urlController.text.trim();
    if (inputUrl.isEmpty) {
      GlassmorphismModal.showAlertModal(
        context: context,
        title: 'Input Diperlukan',
        message: 'Silakan masukkan Link atau ID Google Spreadsheet terlebih dahulu.',
      );
      return;
    }

    setState(() => _isSyncing = true);

    try {
      final items = await SpreadsheetService.fetchSheetData(inputUrl);
      final nowFormatted = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

      setState(() {
        _config.sheetUrl = inputUrl;
        _config.items = items;
        _config.rowCount = items.length;
        _config.lastSyncTime = nowFormatted;
        _isSyncing = false;
      });

      await StorageService.saveSpreadsheetConfig(_config);

      if (mounted) {
        GlassmorphismModal.showAlertModal(
          context: context,
          title: 'Sinkronisasi Berhasil',
          message: 'Berhasil mengunduh dan menyinkronkan ${items.length} data kata kunci dari Google Spreadsheet!',
        );
      }
    } catch (e) {
      setState(() => _isSyncing = false);
      if (mounted) {
        GlassmorphismModal.showAlertModal(
          context: context,
          title: 'Gagal Sinkronisasi',
          message: e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _testKeyword() {
    final input = _testKeywordController.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() => _testResult = 'Masukkan kata kunci pengujian.');
      return;
    }

    String? wildcardReply;

    // 1. Exact Match
    for (final item in _config.items) {
      final raw = item.keyword.trim();
      if (raw == '*') {
        wildcardReply = item.reply;
        continue;
      }
      if (item.matchOption == 0) {
        final kwList = raw.split(',').map((e) => e.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase()).where((k) => k.isNotEmpty);
        if (kwList.any((kw) => kw == input)) {
          setState(() => _testResult = '✅ Cocok (Tepat / Exact):\n"${item.reply}"');
          return;
        }
      }
    }

    // 2. Contains Match
    for (final item in _config.items) {
      final raw = item.keyword.trim();
      if (raw == '*') {
        wildcardReply = item.reply;
        continue;
      }
      if (item.matchOption == 1) {
        final kwList = raw.split(',').map((e) => e.replaceAll(RegExp(r'[?!.]'), '').trim().toLowerCase()).where((k) => k.isNotEmpty);
        if (kwList.any((kw) => input.contains(kw) || kw.contains(input))) {
          setState(() => _testResult = '✅ Cocok (Mengandung / Contains):\n"${item.reply}"');
          return;
        }
      }
    }

    // 3. Fallback Wildcard (*)
    if (wildcardReply != null && wildcardReply.trim().isNotEmpty) {
      setState(() => _testResult = '⭐ Cocok dengan Wildcard (*) Spreadsheet:\n"$wildcardReply"');
      return;
    }

    setState(() => _testResult = '❌ Tidak ada kata kunci yang cocok di spreadsheet.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00A884))),
      );
    }

    final filteredItems = _config.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.keyword.toLowerCase().contains(q) || item.reply.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        elevation: 0,
        title: const Text(
          'Google Spreadsheet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Sinkronkan Sekarang',
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884)),
                  )
                : const Icon(Icons.sync, color: Color(0xFF00A884)),
            onPressed: _isSyncing ? null : _syncSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Master Toggle
            _buildMasterToggle(),
            const SizedBox(height: 16),

            // 2. Input Link/ID Google Sheet
            _buildUrlInputCard(),
            const SizedBox(height: 16),

            // 3. Format Penjelasan Kolom Google Sheet
            _buildColumnFormatGuide(),
            const SizedBox(height: 16),

            // 4. Tombol Sinkronisasi Utama
            _buildSyncButton(),
            const SizedBox(height: 20),

            // 5. Card Pengujian Kata Kunci
            _buildKeywordTester(),
            const SizedBox(height: 20),

            // 6. Header Data List & Search Bar
            _buildDataSectionHeader(filteredItems.length),
            const SizedBox(height: 12),

            // 7. Tabel / List Data Item Terdaftar
            if (filteredItems.isEmpty)
              _buildEmptyState()
            else
              _buildItemsList(filteredItems),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _config.isEnabled ? const Color(0xFF00A884).withOpacity(0.5) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          if (_config.isEnabled)
            BoxShadow(
              color: const Color(0xFF00A884).withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (_config.isEnabled ? const Color(0xFF00A884) : Colors.white12).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.table_chart_rounded,
              color: _config.isEnabled ? const Color(0xFF00A884) : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Balasan Spreadsheet',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  _config.isEnabled ? 'Aktif — Bot merespons data dari sheet' : 'Nonaktif — Balasan sheet dimatikan',
                  style: TextStyle(
                    color: _config.isEnabled ? const Color(0xFF00A884) : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _config.isEnabled,
            activeColor: const Color(0xFF00A884),
            activeTrackColor: const Color(0xFF00A884).withOpacity(0.4),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
            onChanged: (val) {
              setState(() => _config.isEnabled = val);
              _saveConfig();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUrlInputCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link, color: Color(0xFF00A884), size: 18),
              SizedBox(width: 8),
              Text(
                'Link atau ID Google Spreadsheet',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'https://docs.google.com/spreadsheets/d/.../edit',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFF0B141B),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_urlController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _urlController.clear();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.paste, color: Color(0xFF00A884), size: 18),
                    tooltip: 'Tempel dari Clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _urlController.text = data!.text!.trim();
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (_config.lastSyncTime.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF00A884), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Terakhir disinkronkan: ${_config.lastSyncTime} (${_config.rowCount} item)',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColumnFormatGuide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16222A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00A884).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF00A884), size: 16),
              SizedBox(width: 6),
              Text(
                'Panduan Format Kolom Spreadsheet:',
                style: TextStyle(color: Color(0xFF00A884), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildGuideRow('Kolom A', 'Kata Kunci Pesan Masuk (misal: "harga", "ongkir", "katalog")'),
          _buildGuideRow('Kolom B', 'Teks Balasan Otomatis bot'),
          _buildGuideRow('Kolom C', 'Opsi: 0 = Tepat (Exact), 1 = Mengandung (Contains)'),
          _buildGuideRow('Kolom A = *', 'Gunakan "*" jika ingin membalas SEMUA pesan dengan balasan spreadsheet'),
          _buildGuideRow('Variasi/Typo', 'Bisa banyak variasi kata/typo dipisah // atau koma (misal: "ass//askum//assalamuallaikum" atau "harga, tarif")'),
          const SizedBox(height: 6),
          const Text(
            '* Pastikan setelan akses Google Sheet diubah ke "Siapa saja yang memiliki link dapat melihat".',
            style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideRow(String col, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(col, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00A884),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: _isSyncing ? null : _syncSheet,
        child: _isSyncing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Sedang Mengunduh & Memproses...', style: TextStyle(color: Colors.white, fontSize: 14)),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Sinkronkan Sekarang', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  Widget _buildKeywordTester() {
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
          const Text(
            'Uji Kata Kunci Spreadsheet',
            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _testKeywordController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ketik pesan tes (misal: "harga baju")...',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF0B141B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _testKeyword(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16222A),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _testKeyword,
                child: const Text('Tes', style: TextStyle(color: Color(0xFF00A884), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_testResult.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B141B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: Text(
                _testResult,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataSectionHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Data Kata Kunci Terdaftar',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A884).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count Item',
                    style: const TextStyle(color: Color(0xFF00A884), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (_config.items.isNotEmpty) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Cari kata kunci atau balasan...',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF111B21),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF111B21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(Icons.table_rows_outlined, color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Data Spreadsheet',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tempel tautan Google Sheet Anda di atas lalu tekan tombol "Sinkronkan Sekarang".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<SheetReplyItem> items) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isExact = item.matchOption == 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111B21),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00A884).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(color: Color(0xFF00A884), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: item.keyword
                                .split(RegExp(r'//|,|\||\n|;'))
                                .map((k) => k.trim())
                                .where((k) => k.isNotEmpty)
                                .map(
                                  (kw) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      kw,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExact ? const Color(0xFF38BDF8).withOpacity(0.15) : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isExact ? 'Tepat (Exact)' : 'Mengandung (Contains)',
                      style: TextStyle(
                        color: isExact ? const Color(0xFF38BDF8) : const Color(0xFFF59E0B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.reply,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
