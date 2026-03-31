import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'signup_screen.dart';
import 'main_screen.dart';

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
  bool _rememberMe = true; // 💡 خيار تذكرني مفعل افتراضياً

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  Future<void> _loginUser() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAwesomeError("تنبيه", "الرجاء إدخال البريد الإلكتروني وكلمة المرور");
      return;
    }

    setState(() => _isLoading = true);

    final String apiUrl = "${ApiConfig.baseUrl}login.php";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // 💡 حفظ البيانات في الذاكرة (SharedPreferences)
          SharedPreferences prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userId', data['user']['id'].toString());
            await prefs.setString('userEmail', data['user']['email']);
            await prefs.setString(
              'userName',
              "${data['user']['fname']} ${data['user']['lname']}",
            );
          }
          // التأكد من إزالة وضع الزائر
          await prefs.setBool('isGuest', false);

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MainScreen(isGuest: false, userName: data['user']['fname']),
            ),
          );
        } else {
          _showAwesomeError("خطأ", data['message']);
        }
      } else {
        _showAwesomeError("خطأ", "فشل الاتصال بالسيرفر");
      }
    } catch (e) {
      _showAwesomeError("خطأ في الاتصال", "تأكد من تشغيل الإنترنت والسيرفر");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    await prefs.setBool('isLoggedIn', false); // نلغي تسجيل الدخول السابق إن وجد

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen(isGuest: true)),
    );
  }

  void _showAwesomeError(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      btnOkText: 'حسناً',
    ).show();
  }

  void _forgotPasswordDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: 'نسيت كلمة المرور؟',
      desc:
          'ميزة استعادة كلمة المرور عبر الإيميل قيد التطوير وسيتم إضافتها قريباً.',
      btnOkOnPress: () {},
      btnOkColor: primaryColor,
      btnOkText: 'حسناً',
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // الأيقونة العلوية الفخمة
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.truckMedical,
                        size: 50,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  const Text(
                    'أهلاً بك في PharmaSmart',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'سجل دخولك لمتابعة أدويتك وطلباتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // كارت الحقول
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // حقل الإيميل
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'البريد الإلكتروني',
                            prefixIcon: Icon(
                              LucideIcons.mail,
                              color: primaryColor,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // حقل الباسوورد
                        TextField(
                          controller: _passwordController,
                          obscureText: _isPasswordHidden,
                          decoration: InputDecoration(
                            hintText: 'كلمة المرور',
                            prefixIcon: Icon(
                              LucideIcons.lock,
                              color: primaryColor,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordHidden
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                color: Colors.grey,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordHidden = !_isPasswordHidden,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // تذكرني و نسيت كلمة المرور
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) =>
                                  setState(() => _rememberMe = val!),
                              activeColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "تذكرني",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _forgotPasswordDialog,
                        child: Text(
                          "نسيت كلمة المرور؟",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // زر الدخول
                  ElevatedButton(
                    onPressed: _isLoading ? null : _loginUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.4),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 15),

                  // زر الزائر
                  OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: Icon(LucideIcons.user, color: primaryColor, size: 20),
                    label: Text(
                      'تصفح التطبيق كزائر',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      side: BorderSide(
                        color: primaryColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // إنشاء حساب
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'مريض جديد؟',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        ),
                        child: Text(
                          'إنشاء حساب',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
