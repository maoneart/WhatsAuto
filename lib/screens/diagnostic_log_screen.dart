import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/glassmorphism_modal.dart';

class DiagnosticLogScreen extends StatefulWidget {
  const DiagnosticLogScreen({super.key});

  @override
  State<DiagnosticLogScreen> createState() => _DiagnosticLogScreenState();
}

class _DiagnosticLogScreenState extends State<DiagnosticLogScreen> {
  static const MethodChannel _platformChannel = MethodChannel('com.maoneart.maoneauto/service');

  List<String> _logs = [];
  bool _isLoading = true;
  bool _isNotificationPermissionGranted = false;
  bool _isListenerConnected = false;
  Timer? _pollingTimer;

  final TextEditingController _testMessageController = TextEditingController(text: 'hay');
  String _simulationResult = '';
  bool _isSimulating = false;

  @override
  void initState() {
    super.initState();
    _fetchStatusAndLogs();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchLogsOnly();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _testMessageController.dispose();
    super.dispose();
  }

  Future<void> _fetchStatusAndLogs() async {
    try {
      final bool isEnabled = await _platformChannel.invokeMethod('isNotificationServiceEnabled') ?? false;
      final bool isConnected = await _platformChannel.invokeMethod('isListenerConnected') ?? false;
      final List<dynamic>? rawLogs = await _platformChannel.invokeMethod('getServiceLogs');

      if (mounted) {
        setState(() {
          _isNotificationPermissionGranted = isEnabled;
          _isListenerConnected = isConnected;
          _logs = rawLogs?.map((e) => e.toString()).toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchLogsOnly() async {
    try {
      final bool isConnected = await _platformChannel.invokeMethod('isListenerConnected') ?? false;
      final List<dynamic>? rawLogs = await _platformChannel.invokeMethod('getServiceLogs');

      if (mounted) {
        setState(() {
          _isListenerConnected = isConnected;
          _logs = rawLogs?.map((e) => e.toString()).toList() ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _clearLogs() async {
    try {
      await _platformChannel.invokeMethod('clearServiceLogs');
      setState(() {
        _logs.clear();
      });
    } catch (_) {}
  }

  Future<void> _reconnectService() async {
    try {
      await _platformChannel.invokeMethod('rebindService');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meminta Android menyambungkan ulang listener notifikasi...'),
          backgroundColor: Color(0xFF00A884),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      _fetchStatusAndLogs();
    } catch (_) {}
  }

  Future<void> _runSimulation(String text) async {
    setState(() {
      _isSimulating = true;
      _simulationResult = '';
    });

    try {
      final String? reply = await _platformChannel.invokeMethod('simulateTestMessage', {
        'sender': 'Penguji WA',
        'message': text,
      });

      setState(() {
        _simulationResult = reply ?? 'Tidak ada respon.';
        _isSimulating = false;
      });
      _fetchLogsOnly();
    } catch (e) {
      setState(() {
        _simulationResult = 'Error simulasi: $e';
        _isSimulating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B141B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111B21),
        title: const Text(
          'Live Monitor & Log Diagnostik',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Segarkan Log',
            onPressed: _fetchStatusAndLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
            tooltip: 'Hapus Log',
            onPressed: () {
              GlassmorphismModal.showConfirmModal(
                context: context,
                title: 'Hapus Seluruh Log',
                message: 'Apakah Anda ingin membersihkan seluruh rekaman log diagnostik?',
                confirmText: 'Bersihkan',
                cancelText: 'Batal',
                confirmColor: Colors.redAccent,
                icon: Icons.delete_outline,
              ).then((confirmed) {
                if (confirmed == true) {
                  _clearLogs();
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00A884)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Status Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          title: 'Izin Notifikasi',
                          subtitle: _isNotificationPermissionGranted ? 'AKTIF DI SISTEM' : 'BELUM AKTIF',
                          icon: _isNotificationPermissionGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: _isNotificationPermissionGranted ? const Color(0xFF00A884) : const Color(0xFFEF4444),
                          onTap: () {
                            _platformChannel.invokeMethod('openNotificationSettings');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          title: 'Listener Background',
                          subtitle: _isListenerConnected ? 'TERHUBUNG' : 'TERPUTUS',
                          icon: _isListenerConnected ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                          color: _isListenerConnected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          onTap: _reconnectService,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (!_isNotificationPermissionGranted || !_isListenerConnected)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23180F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline, color: Color(0xFFF59E0B), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Petunjuk Mengaktifkan Akses:',
                                style: TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '1. Buka "Pengaturan Akses Notifikasi" lalu pastikan sakelar MaoneAuto menyala.\n2. Jika tombol sakelar abu-abu (Android 13+), buka Info Aplikasi -> titik 3 (⋮) pojok kanan atas -> pilih "Izinkan setelan yang dibatasi".\n3. Jika izin sudah nyala tapi Listener Terputus, matikan sakelar MaoneAuto lalu hidupkan kembali.',
                            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A884),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.settings, size: 15, color: Colors.white),
                                    label: const Text('Buka Pengaturan', style: TextStyle(fontSize: 11.5, color: Colors.white)),
                                    onPressed: () => _platformChannel.invokeMethod('openNotificationSettings'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: const Color(0xFF00A884).withOpacity(0.5)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.refresh, size: 15, color: Color(0xFF00A884)),
                                    label: const Text('Konek Ulang', style: TextStyle(fontSize: 11.5, color: Color(0xFF00A884))),
                                    onPressed: _reconnectService,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),

                  // 2. Kotak Uji Langsung Pesan Masuk (Native Test Runner)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111B21),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF00A884).withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science_outlined, color: Color(0xFF00A884), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Uji Simulasi Logika Balasan',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kirim kata kunci langsung ke background engine untuk memverifikasi apakah aturan terdeteksi:',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickTestChip('hay'),
                            _buildQuickTestChip('menu'),
                            _buildQuickTestChip('ass'),
                            _buildQuickTestChip('halo'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _testMessageController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Ketik pesan tes...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  filled: true,
                                  fillColor: const Color(0xFF0B141B),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 38,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00A884),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                ),
                                onPressed: _isSimulating ? null : () => _runSimulation(_testMessageController.text.trim()),
                                child: _isSimulating
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Tes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        if (_simulationResult.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F2620),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF00A884).withOpacity(0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Hasil Respon Bot:', style: TextStyle(fontSize: 11, color: Color(0xFF00A884), fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(_simulationResult, style: const TextStyle(fontSize: 12.5, color: Colors.white, height: 1.3)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Live Log Terminal View
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.terminal_rounded, color: Color(0xFF38BDF8), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Live Terminal Log',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF38BDF8).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${_logs.length} entri',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 220),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF050B0E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: _logs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined, color: Colors.white.withOpacity(0.2), size: 36),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada aktivitas notifikasi tercatat.\nKirim pesan WhatsApp dari HP lain untuk melihat log real-time di sini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _logs.reversed.length,
                            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.06), height: 10),
                            itemBuilder: (context, index) {
                              final line = _logs.reversed.elementAt(index);
                              Color textColor = Colors.white70;
                              if (line.contains('✅') || line.contains('TERKIRIM')) {
                                textColor = const Color(0xFF4ADE80);
                              } else if (line.contains('❌') || line.contains('Error') || line.contains('Gagal')) {
                                textColor = const Color(0xFFF87171);
                              } else if (line.contains('⚠️') || line.contains('Abaikan') || line.contains('diabaikan')) {
                                textColor = const Color(0xFFFBBF24);
                              } else if (line.contains('📩') || line.contains('Notif masuk')) {
                                textColor = const Color(0xFF38BDF8);
                              } else if (line.contains('🧪')) {
                                textColor = const Color(0xFFA78BFA);
                              }

                              return Text(
                                line,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11.5,
                                  color: textColor,
                                  height: 1.35,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQuickTestChip(String keyword) {
    return ActionChip(
      label: Text(keyword, style: const TextStyle(fontSize: 11.5, color: Colors.white)),
      backgroundColor: const Color(0xFF1A2730),
      side: BorderSide(color: const Color(0xFF00A884).withOpacity(0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onPressed: () {
        _testMessageController.text = keyword;
        _runSimulation(keyword);
      },
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF111B21),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
