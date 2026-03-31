import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const PharmaSmartApp());
}

class PharmaSmartApp extends StatelessWidget {
  const PharmaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PharmaSmart',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(
          0xFFF2FBF5,
        ), // 💡 توحيد لون الخلفية
        fontFamily: 'Tahoma',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // 💡 الدالة الذكية لفحص الذاكرة
  Future<void> _checkLoginStatus() async {
    // ننتظر 3 ثوانٍ لجمالية شاشة البداية
    await Future.delayed(const Duration(seconds: 3));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool isGuest = prefs.getBool('isGuest') ?? false;
    String? userName = prefs.getString('userName');

    if (!mounted) return;

    if (isLoggedIn || isGuest) {
      // المريض مسجل دخوله مسبقاً أو اختار الدخول كزائر -> نذهب للرئيسية مباشرة
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainScreen(isGuest: isGuest, userName: userName),
        ),
      );
    } else {
      // المريض غير مسجل -> نذهب لشاشة الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A7A48),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_pharmacy, size: 100.0, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'PharmaSmart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'صيدليتك بين يديك',
              style: TextStyle(color: Colors.white70, fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}
