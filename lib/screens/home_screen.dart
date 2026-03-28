// ==========================================
// شاشة رئيسية مؤقتة (سنصممها بشكل احترافي في المرحلة القادمة)
// ==========================================
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatelessWidget {
  final bool isGuest; // متغير لمعرفة هل هو زائر أم مريض مسجل
  final String? userName;

  const HomeScreen({Key? key, required this.isGuest, this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A7A48),
        title: const Text('PharmaSmart', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Icon(isGuest ? LucideIcons.userCircle : LucideIcons.checkCircle2, size: 80, color: const Color(0xFF0A7A48)),
            const SizedBox(height: 20),
            Text(
              isGuest ? 'مرحباً بك أيها الزائر!' : 'مرحباً $userName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              isGuest ? 'تصفح براحتك، لكن لا تنسَ تسجيل الدخول للطلب' : 'أنت الآن مسجل دخولك في النظام',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            // زر تسجيل الخروج / أو إنشاء حساب للزائر
            ElevatedButton.icon(
              icon: Icon(isGuest ? LucideIcons.logIn : LucideIcons.logOut, color: Colors.white),
              label: Text(isGuest ? 'تسجيل الدخول / إنشاء حساب' : 'تسجيل الخروج', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: isGuest ? Colors.blue : Colors.red, padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)),
              onPressed: () async {
                // مسح الذاكرة والعودة لشاشة الدخول
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              },
            )
          ],
        ),
      ),
    );
  }
}