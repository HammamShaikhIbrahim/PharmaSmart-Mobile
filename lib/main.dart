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
        scaffoldBackgroundColor: const Color(0xFFF2FBF5),
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
  // للتحكم بحركة ظهور اللوجو
  bool _startAnimation = false;

  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    // تشغيل الحركة بعد 100 جزء من الثانية لتبدو سلسة
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _startAnimation = true);
    });

    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // عرض الشاشة لمدة 3 ثوانٍ
    await Future.delayed(const Duration(seconds: 4));

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool isGuest = prefs.getBool('isGuest') ?? false;
    String? userName = prefs.getString('userName');

    if (!mounted) return;

    // انتقال ناعم جداً للصفحة التالية (Fade In)
    if (isLoggedIn || isGuest) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) =>
              MainScreen(isGuest: isGuest, userName: userName),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => const LoginScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 💡 1. خلفية متدرجة فخمة وناعمة جداً مأخوذة من لون اللوجو
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9), // أخضر نعناعي فاتح جداً
              Colors.white, // أبيض في المنتصف
              Color(0xFFF2FBF5), // لون التطبيق الأساسي الفاتح
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==========================================
            // 1. اللوجو الخاص بك (مع حركة الدخول)
            // ==========================================
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: _startAnimation ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 1500),
                scale: _startAnimation ? 1.0 : 0.85,
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // اللوجو الفخم الخاص بك
                    Image.asset(
                      'assets/images/logo.png',
                      width: 170, // 💡 صغرت الحجم شعرة بسيطة ليكون أرتب
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 25),

                    const Text(
                      'PharmaSmart',
                      style: TextStyle(
                        color: Color(0xFF0A7A48), // أخضر يطابق اللوجو
                        fontSize: 30.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'صيدليتك بين يديك',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // 2. مؤشر التحميل الأنيق في الأسفل
            // ==========================================
            Positioned(
              bottom: 60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _startAnimation ? 1.0 : 0.0,
                child: Column(
                  children: [
                    // 💡 استخدمنا دائرة تحميل أنيقة وبسيطة بدل تكرار اللوجو
                    const SizedBox(
                      width: 35,
                      height: 35,
                      child: CircularProgressIndicator(
                        color: Color(0xFF0A7A48),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'جاري التجهيز...',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
