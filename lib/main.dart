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
    await Future.delayed(const Duration(seconds: 3));

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
      // 💡 خلفية بيضاء نظيفة ومريحة للعين تتدرج بشكل خفيف جداً
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF9FDFB), // لون أخضر ثلجي خفيييف جداً في الأسفل
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
                scale: _startAnimation ? 1.0 : 0.8, // يكبر من 80% إلى 100%
                curve: Curves.easeOutBack, // حركة ارتدادية راقية
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 💡 استدعاء اللوجو الخاص بك هنا
                    // تأكد أن مسار الصورة واسمها يتطابق مع ما وضعته في مجلد assets
                    Image.asset(
                      'assets/images/logo.png', // مسار صورتك
                      width: 180, // يمكنك تكبير أو تصغير الرقم حسب حجم اللوجو
                      height: 180,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

                    // يمكنك ترك هذا النص أو مسحه إذا كان اللوجو يحتوي على الاسم
                    const Text(
                      'PharmaSmart',
                      style: TextStyle(
                        color: Color(0xFF0A7A48), // أخضر التطبيق
                        fontSize: 28.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'صيدليتك بين يديك',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14.0,
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
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CircularProgressIndicator(
                        color: primaryColor, // أخضر
                        strokeWidth: 3,
                        backgroundColor: primaryColor.withOpacity(0.1),
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
