import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../widgets/glassmorphism_modal.dart';
import 'home_tab.dart';
import 'contacts_tab.dart';
import 'tools_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  AppSettings _settings = AppSettings();
  bool _isLoading = true;
  bool _isNotificationPermissionGranted = true;
  bool _isListenerConnected = false;

  static const MethodChannel _platformChannel = MethodChannel('com.maoneart.maoneauto/service');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission(showDialogIfNeeded: false);
    }
  }

  Future<void> _loadInitialData() async {
    final settings = await StorageService.loadSettings();
    // Pastikan seluruh kunci tersimpan ke native SharedPreferences saat startup
    await StorageService.saveSettings(settings);
    await StorageService.loadMenuNodes();
    await StorageService.loadKeywordReplies();

    setState(() {
      _settings = settings;
      _isLoading = false;
    });

    // Periksa izin notifikasi Android setelah render pertama selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNotificationPermission(showDialogIfNeeded: true);
    });
  }

  Future<void> _checkNotificationPermission({bool showDialogIfNeeded = false}) async {
    try {
      await _platformChannel.invokeMethod('enableNotificationComponent');
      final bool isEnabled = await _platformChannel.invokeMethod('isNotificationServiceEnabled') ?? false;
      final bool isConnected = await _platformChannel.invokeMethod('isListenerConnected') ?? false;
      if (mounted) {
        setState(() {
          _isNotificationPermissionGranted = isEnabled;
          _isListenerConnected = isConnected;
        });

        if ((!isEnabled || !isConnected) && showDialogIfNeeded) {
          final openSettings = await GlassmorphismModal.showConfirmModal(
            context: context,
            title: !isEnabled ? 'Izin Akses Notifikasi Dibutuhkan' : 'Layanan Notifikasi Belum Terhubung',
            message: !isEnabled
                ? 'MaoneAuto memerlukan izin "Akses Notifikasi" agar bot dapat membaca pesan masuk dan mengirim balasan otomatis ke WhatsApp.\n\n⚠️ Khusus Android 13/14/15:\nJika tombol toggle abu-abu, buka "Info Aplikasi" -> tekan titik 3 (⋮) di pojok kanan atas -> pilih "Izinkan setelan yang dibatasi".'
                : 'Izin notifikasi telah diberikan, namun sistem Android belum mengaktifkan koneksi listener.\n\nSilakan buka Pengaturan Notifikasi, matikan sakelar MaoneAuto lalu hidupkan kembali.',
            confirmText: 'Buka Pengaturan',
            cancelText: 'Nanti Saja',
            confirmColor: const Color(0xFF00A884),
            icon: Icons.notifications_active_rounded,
          );

          if (openSettings == true) {
            _openSettings();
          }
        }
      }
    } catch (_) {}
  }

  void _openSettings() {
    _platformChannel.invokeMethod('openNotificationSettings');
  }

  void _openAppDetails() {
    _platformChannel.invokeMethod('openAppDetailsSettings');
  }

  void _rebindService() {
    _platformChannel.invokeMethod('rebindService');
  }

  void _onSettingsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B141B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00A884)),
        ),
      );
    }

    final List<Widget> tabs = [
      HomeTab(
        settings: _settings,
        onSettingsChanged: _onSettingsChanged,
        isNotificationPermissionGranted: _isNotificationPermissionGranted,
        isListenerConnected: _isListenerConnected,
        onRequestPermission: _openSettings,
        onOpenAppDetails: _openAppDetails,
      ),
      ContactsTab(settings: _settings, onSettingsChanged: _onSettingsChanged),
      ToolsTab(
        settings: _settings,
        onSettingsChanged: _onSettingsChanged,
        isNotificationPermissionGranted: _isNotificationPermissionGranted,
        onRequestPermission: _openSettings,
        onOpenAppDetails: _openAppDetails,
        onRebindService: _rebindService,
      ),
    ];

    return Scaffold(
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111B21),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.06), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF111B21),
          selectedItemColor: const Color(0xFF00A884),
          unselectedItemColor: const Color(0xFF8696A0),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Kontak',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.widgets_outlined),
              activeIcon: Icon(Icons.widgets),
              label: 'Alat',
            ),
          ],
        ),
      ),
    );
  }
}
