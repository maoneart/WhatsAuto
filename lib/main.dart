import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfigurasi System UI Overlay agar senada dengan Dark Mode WhatsAuto
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111B21),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WhatsAutoApp());
}

class WhatsAutoApp extends StatelessWidget {
  const WhatsAutoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsAuto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B141B),
        primaryColor: const Color(0xFF00A884),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00A884),
          secondary: Color(0xFF00A884),
          surface: Color(0xFF111B21),
          background: Color(0xFF0B141B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF111B21),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        dialogBackgroundColor: const Color(0xFF1F2C34),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
