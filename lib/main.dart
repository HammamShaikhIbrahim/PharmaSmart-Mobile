// ==========================================
// استيراد المكتبات الأساسية | Importing core libraries
// ==========================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; //  إضافة مكتبة الموقع هنا للطلب المبكر

import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart'; 

// ==========================================
// دالة التشغيل الرئيسية | Main execution function
// ==========================================
void main() {
  runApp(const PharmaSmartApp());
}

// ==========================================
// إعدادات التطبيق الأساسية | Main App Configuration
// ==========================================
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

// ==========================================
// شاشة البداية (السبلاش) | Splash Screen
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ==========================================
  // متغيرات التحكم بالحركة | Animation control variables
  // ==========================================
  bool _startAnimation = false;
  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    // ==========================================
    // تشغيل الحركة بسلاسة | Start animation smoothly
    // ==========================================
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _startAnimation = true);
    });

    _checkStatusAndPermissions();
  }

  // ==========================================
  //  فحص حالة المستخدم وطلب إذن الموقع بصمت | Check status & silently request GPS
  // ==========================================
  Future<void> _checkStatusAndPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('isFirstTime') ?? true;
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    bool isGuest = prefs.getBool('isGuest') ?? false;
    String? userName = prefs.getString('userName');

    // إذا لم تكن المرة الأولى، نطلب إذن الموقع هنا بهدوء أثناء تحميل السبلاش سكرين
    if (!isFirstTime) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            await Geolocator.requestPermission();
          }
        }
      } catch (e) {
        debugPrint("Silent GPS request failed: $e");
      }
    }

    // الانتظار قليلاً ليتمكن المستخدم من رؤية اللوجو
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // ==========================================
    // التوجيه الذكي | Smart Routing
    // ==========================================
    Widget nextScreen;
    if (isFirstTime) {
      nextScreen = const OnboardingScreen();
    } else if (isLoggedIn || isGuest) {
      nextScreen = MainScreen(isGuest: isGuest, userName: userName);
    } else {
      nextScreen = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, __, ___) => nextScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // بناء واجهة المستخدم | Build UI
    // ==========================================
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F5E9), 
              Colors.white, 
              Color(0xFFF2FBF5), 
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ==========================================
            // حركة اللوجو | Logo Animation
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
                    Image.asset(
                      'assets/images/logo.png',
                      width: 170, 
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'PharmaSmart',
                      style: TextStyle(
                        color: Color(0xFF0A7A48), 
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
            // مؤشر التحميل السفلي | Bottom Loading Indicator
            // ==========================================
            Positioned(
              bottom: 60,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 1000),
                opacity: _startAnimation ? 1.0 : 0.0,
                child: Column(
                  children: [
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