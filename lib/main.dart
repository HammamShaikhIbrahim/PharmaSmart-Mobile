// 1. استدعاء مكتبة واجهات فلاتر الأساسية
import 'package:flutter/material.dart';

// 2. استدعاء شاشة تسجيل الدخول (الملف الذي سننشئه في الخطوة القادمة)
import 'screens/login_screen.dart';

// 3. الدالة الرئيسية التي تشغل التطبيق
void main() {
  runApp(const PharmaSmartApp());
}

// 4. الكلاس الرئيسي لتهيئة التطبيق بالكامل
class PharmaSmartApp extends StatelessWidget {
  const PharmaSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // إخفاء شريط الديباج الأحمر
      debugShowCheckedModeBanner: false,
      title: 'PharmaSmart',
      
      // إعدادات الثيم والألوان
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50], // لون الخلفية العام
        // جعل التطبيق يدعم اللغة العربية من اليمين لليسار كإعداد افتراضي للنصوص
        fontFamily: 'Tahoma', // خط افتراضي مؤقت
      ),
      
      // أول شاشة ستفتح في التطبيق هي شاشة البداية
      home: const SplashScreen(),
    );
  }
}

// 5. كلاس شاشة البداية (Splash Screen) - وهي شاشة ذكية (Stateful) لتنفيذ مؤقت زمني
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  // دالة initState تعمل تلقائياً فور فتح هذه الشاشة وقبل رسم أي شيء
  @override
  void initState() {
    super.initState();
    
    // أمر تأخير (مؤقت) لمدة 3 ثوانٍ
    Future.delayed(const Duration(seconds: 3), () {
      // بعد 3 ثوانٍ، انتقل لشاشة الدخول وقم بإغلاق شاشة البداية تماماً
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  // كود تصميم الشاشة الخضراء
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A7A48), // اللون الأخضر الخاص بك
      body: Center( // وضع العناصر في المنتصف
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            // أيقونة الصيدلية
            Icon(
              Icons.local_pharmacy,
              size: 100.0,
              color: Colors.white,
            ),
            SizedBox(height: 20), // مسافة فارغة
            // اسم التطبيق
            Text(
              'PharmaSmart',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            // الشعار اللفظي
            Text(
              'صيدليتك بين يديك',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}