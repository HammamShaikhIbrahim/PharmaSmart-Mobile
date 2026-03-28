// ==========================================
// 1. استدعاء المكتبات الأساسية للتطبيق
// ==========================================
import '../config/api_config.dart'; // استدعاء ملف الإعدادات
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert'; // لتحويل البيانات إلى JSON
import 'package:http/http.dart' as http; // للاتصال بالسيرفر (API)
import 'package:shared_preferences/shared_preferences.dart'; // مكتبة الذاكرة

import 'signup_screen.dart'; // شاشة إنشاء الحساب
import 'home_screen.dart';   // الشاشة الرئيسية (التي صنعناها للتو)

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ==========================================
  // 2. المتغيرات ومتحكمات النصوص
  // ==========================================
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordHidden = true; // لإخفاء الباسوورد
  bool _isLoading = false; // لإظهار دائرة التحميل أثناء الاتصال بالسيرفر

  // ==========================================
  // 3. دالة تسجيل الدخول (Login API Call)
  // ==========================================
  Future<void> _loginUser() async {
    // التأكد من عدم ترك الحقول فارغة
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("تنبيه", "الرجاء إدخال البريد الإلكتروني وكلمة المرور", isError: true);
      return;
    }

    setState(() { _isLoading = true; }); // تفعيل دائرة التحميل

  // استخدام الرابط من ملف الإعدادات + اسم ملف الـ PHP
  final String apiUrl = "${ApiConfig.baseUrl}login.php";
  
    try {
      // إرسال الطلب للسيرفر
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text,
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          // ==========================================
          // 4. حفظ بيانات المستخدم في ذاكرة الهاتف لكي يبقى مسجلاً دخوله
          // ==========================================
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', data['user']['id'].toString());
          await prefs.setString('userName', data['user']['fname'] + " " + data['user']['lname']);
          
          // الانتقال إلى الشاشة الرئيسية (كمستخدم مسجل)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(isGuest: false, userName: data['user']['fname'])),
          );
        } else {
          // رسالة خطأ (باسوورد غلط أو إيميل غير موجود)
          _showMessage("خطأ", data['message'], isError: true);
        }
      } else {
        _showMessage("خطأ", "فشل الاتصال بالسيرفر. رمز الخطأ: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال", "تأكد من تشغيل السيرفر. التفاصيل: $e", isError: true);
    } finally {
      setState(() { _isLoading = false; }); // إيقاف دائرة التحميل
    }
  }

  // ==========================================
  // 5. دالة الانتقال كـ (زائر - Guest)
  // ==========================================
  Future<void> _continueAsGuest() async {
    // نحفظ في الذاكرة أنه زائر
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);

    // ننتقل فوراً للشاشة الرئيسية
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen(isGuest: true)),
    );
  }

  // דالة الرسائل المنبثقة
  void _showMessage(String title, String message, {required bool isError}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children:[
            Icon(isError ? LucideIcons.xCircle : LucideIcons.checkCircle2, color: isError ? Colors.red : const Color(0xFF0A7A48)),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: isError ? Colors.red : const Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions:[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("حسناً", style: TextStyle(color: isError ? Colors.red : const Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. واجهة الشاشة
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl, // لغة عربية
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                const SizedBox(height: 40),
                const Icon(LucideIcons.heartPulse, size: 80, color: Color(0xFF0A7A48)),
                const SizedBox(height: 20),
                const Text('مرحباً بك مجدداً', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                const Text('قم بتسجيل الدخول لطلب أدويتك بسهولة', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 40),
                
                // مربع الإيميل
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF0A7A48)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: const BorderSide(color: Color(0xFF0A7A48), width: 2)),
                  ),
                ),
                const SizedBox(height: 20),
                
                // مربع الباسوورد
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF0A7A48)),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0), borderSide: const BorderSide(color: Color(0xFF0A7A48), width: 2)),
                  ),
                ),
                const SizedBox(height: 10),
                
                // زر نسيان الباسوورد
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () {}, child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: Color(0xFF0A7A48)))),
                ),
                const SizedBox(height: 15),
                
                // زر تسجيل الدخول
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7A48),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                    elevation: 3,
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                
                const SizedBox(height: 15),

                // 💡 الزر الجديد: الدخول كزائر (مفرغ من الداخل ليعطي انطباع أنه خيار ثانوي)
                OutlinedButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(LucideIcons.user, color: Color(0xFF0A7A48)),
                  label: const Text('تصفح التطبيق كزائر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48))),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0A7A48), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // زر إنشاء حساب
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    const Text('ليس لديك حساب؟', style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen()));
                      },
                      child: const Text('إنشاء حساب جديد', style: TextStyle(color: Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}