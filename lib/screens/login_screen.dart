import '../config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'signup_screen.dart';
import 'main_screen.dart'; // الربط بالشاشة الحاوية الجديدة

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("تنبيه", "الرجاء إدخال البريد الإلكتروني وكلمة المرور", isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    final String apiUrl = "${ApiConfig.baseUrl}login.php";
    try {
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
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userId', data['user']['id'].toString());
          await prefs.setString('userName', data['user']['fname'] + " " + data['user']['lname']);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainScreen(isGuest: false, userName: data['user']['fname'])),
          );
        } else {
          _showMessage("خطأ", data['message'], isError: true);
        }
      } else {
        _showMessage("خطأ", "فشل الاتصال بالسيرفر", isError: true);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال", "تأكد من تشغيل السيرفر. التفاصيل: $e", isError: true);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _continueAsGuest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen(isGuest: true)),
    );
  }

  void _showMessage(String title, String message, {required bool isError}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: TextStyle(color: isError ? Colors.red : const Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("حسناً")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(LucideIcons.heartPulse, size: 80, color: Color(0xFF0A7A48)),
                const SizedBox(height: 20),
                const Text('مرحباً بك مجدداً', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF0A7A48)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF0A7A48)),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye),
                      onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7A48),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: _continueAsGuest,
                  icon: const Icon(LucideIcons.user, color: Color(0xFF0A7A48)),
                  label: const Text('تصفح التطبيق كزائر', style: TextStyle(color: Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF0A7A48)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                  ),
                ),
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  child: const Text('إنشاء حساب جديد', style: TextStyle(color: Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}