import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import 'home_tab.dart';
import 'contacts_tab.dart';
import 'tools_tab.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  static const MethodChannel _platformChannel = MethodChannel('com.maoneart.maoneauto/service');

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final settings = await StorageService.loadSettings();
    // Pastikan menu nodes juga termuat ke SharedPreferences native
    await StorageService.loadMenuNodes();

    setState(() {
      _settings = settings;
      _isLoading = false;
    });

    // Periksa izin notifikasi Android di latar belakang
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    try {
      final bool isEnabled = await _platformChannel.invokeMethod('isNotificationServiceEnabled');
      if (!isEnabled && mounted) {
        // Tampilkan info singkat untuk mengaktifkan akses notifikasi jika belum aktif
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1F2C34),
            content: const Text(
              'Aktifkan Akses Notifikasi agar MaoneAuto dapat membalas otomatis',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            action: SnackBarAction(
              label: 'PENGATURAN',
              textColor: const Color(0xFF00A884),
              onPressed: () {
                _platformChannel.invokeMethod('openNotificationSettings');
              },
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (_) {}
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
      HomeTab(settings: _settings, onSettingsChanged: _onSettingsChanged),
      ContactsTab(settings: _settings, onSettingsChanged: _onSettingsChanged),
      ToolsTab(settings: _settings, onSettingsChanged: _onSettingsChanged),
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
              icon: Icon(Icons.home),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Kontak',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work),
              label: 'Alat',
            ),
          ],
        ),
      ),
    );
  }
}
