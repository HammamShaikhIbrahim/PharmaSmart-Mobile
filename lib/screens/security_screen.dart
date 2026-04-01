import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../config/api_config.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hideOld = true;
  bool _hideNew = true;
  String _userId = '';

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';
    _emailController.text = prefs.getString('userEmail') ?? '';
    setState(() => _isLoading = false);
  }

  Future<void> _updateSecurity() async {
    if (_emailController.text.trim().isEmpty || _oldPassController.text.isEmpty) {
      _showWarning('تنبيه', 'البريد الإلكتروني وكلمة المرور الحالية حقول مطلوبة.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}update_security.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": _userId,
          "email": _emailController.text.trim(),
          "old_pass": _oldPassController.text,
          "new_pass": _newPassController.text.isEmpty ? null : _newPassController.text,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userEmail', _emailController.text.trim());

          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم التحديث',
            desc: 'تم تحديث بيانات الأمان بنجاح!',
            btnOkColor: primaryColor,
            btnOkText: 'ممتاز',
            dismissOnTouchOutside: false,
            btnOkOnPress: () {
              // 💡 تفريغ الخانات عند النجاح
              _oldPassController.clear();
              _newPassController.clear();
              Navigator.pop(context);
            },
          ).show();
        } else {
          _showError(data['message'] ?? 'فشل التحديث');
        }
      } else {
        _showError('خطأ في الاتصال بالسيرفر');
      }
    } catch (e) {
      _showError('تأكد من اتصال السيرفر والإنترنت');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    AwesomeDialog(context: context, dialogType: DialogType.error, title: 'خطأ', desc: msg, btnOkColor: Colors.redAccent, btnOkText: 'حسناً', btnOkOnPress: () {}).show();
  }

  void _showWarning(String title, String desc) {
    AwesomeDialog(context: context, dialogType: DialogType.warning, title: title, desc: desc, btnOkColor: Colors.orange, btnOkText: 'حسناً', btnOkOnPress: () {}).show();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('الخصوصية والأمان', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(LucideIcons.arrowRight, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: primaryColor.withOpacity(0.1), border: Border.all(color: Colors.white, width: 4), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                        child: Center(child: Icon(LucideIcons.shieldCheck, size: 40, color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 35),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.grey.shade100)),
                      child: Column(
                        children: [
                          _buildCleanField('البريد الإلكتروني', LucideIcons.mail, _emailController),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanField('كلمة المرور الحالية', LucideIcons.lock, _oldPassController, isPassword: true, isHidden: _hideOld, onToggle: () => setState(() => _hideOld = !_hideOld)),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanField('كلمة المرور الجديدة (اختياري)', LucideIcons.key, _newPassController, isPassword: true, isHidden: _hideNew, onToggle: () => setState(() => _hideNew = !_hideNew)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Icon(LucideIcons.info, size: 16, color: Colors.orange.shade400),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('يجب إدخال كلمة المرور الحالية لتتمكن من تحديث بريدك أو تغيير كلمة المرور.', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateSecurity,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 5, shadowColor: primaryColor.withOpacity(0.3)),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('تحديث بيانات الأمان', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCleanField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, bool isHidden = false, VoidCallback? onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          obscureText: isHidden,
          textAlign: TextAlign.left,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: primaryColor),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: isPassword ? IconButton(icon: Icon(isHidden ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: Colors.grey), onPressed: onToggle) : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }
}