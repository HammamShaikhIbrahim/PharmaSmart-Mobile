import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../config/api_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userId = '';

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5); // 💡 اللون الموحد الجديد

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fnameController.dispose();
    _lnameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 💡 جلب بيانات المريض الحقيقية لوضعها في الخانات
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';

    if (_userId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}get_profile.php?user_id=$_userId"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _fnameController.text = data['data']['Fname'] ?? '';
            _lnameController.text = data['data']['Lname'] ?? '';
            _phoneController.text = data['data']['Phone'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
      setState(() => _isLoading = false);
    }
  }

  // 💡 إرسال البيانات المحدثة للسيرفر (update_profile.php)
  Future<void> _updateProfile() async {
    if (_fnameController.text.trim().isEmpty ||
        _lnameController.text.trim().isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'تنبيه',
        desc: 'الاسم الأول واسم العائلة حقول إجبارية.',
        btnOkColor: Colors.orange,
        btnOkText: 'حسناً',
        btnOkOnPress: () {},
      ).show();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}update_profile.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": _userId,
          "fname": _fnameController.text.trim(),
          "lname": _lnameController.text.trim(),
          "phone": _phoneController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          // تحديث الاسم في الذاكرة المحلية (SharedPreferences) لكي ينعكس في كل التطبيق
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'userName',
            '${_fnameController.text.trim()} ${_lnameController.text.trim()}',
          );

          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم بنجاح',
            desc: 'تم تحديث بياناتك الشخصية بنجاح!',
            btnOkColor: primaryColor,
            btnOkText: 'ممتاز',
            dismissOnTouchOutside: false,
            btnOkOnPress: () {
              Navigator.pop(context); // العودة لصفحة البروفايل بعد النجاح
            },
          ).show();
        } else {
          _showError(data['message'] ?? 'فشل التحديث');
        }
      } else {
        _showError('خطأ في السيرفر');
      }
    } catch (e) {
      _showError('تأكد من اتصالك بالإنترنت والسيرفر');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String msg) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'خطأ',
      desc: msg,
      btnOkColor: Colors.redAccent,
      btnOkText: 'حسناً',
      btnOkOnPress: () {},
    ).show();
  }

  // لاستخراج الحرف الأول من الاسم للصورة الرمزية
  String get _initial {
    return _fnameController.text.isNotEmpty
        ? _fnameController.text[0].toUpperCase()
        : 'م';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor, // 💡 توحيد اللون
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          centerTitle: true,
          title: const Text(
            'تعديل الملف الشخصي',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // صورة البروفايل
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor.withOpacity(0.1),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _initial,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.camera,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // الحقول داخل كارد زجاجي أبيض
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildCleanTextField(
                            'الاسم الأول',
                            'أدخل اسمك الأول',
                            LucideIcons.user,
                            _fnameController,
                          ),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanTextField(
                            'اسم العائلة',
                            'أدخل اسم العائلة',
                            LucideIcons.user,
                            _lnameController,
                          ),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanTextField(
                            'رقم الهاتف',
                            '05XXXXXXXX',
                            LucideIcons.phone,
                            _phoneController,
                            isPhone: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // زر الحفظ (أصبح بالأخضر بدل الأسود)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.3),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCleanTextField(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          // 💡 التعديل هنا: محاذاة لليسار إذا كان هاتف، ولليمين إذا كان اسم
          textAlign: isPhone ? TextAlign.left : TextAlign.right,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            // جعل الأيقونة تظهر دائماً في الجهة المناسبة
            prefixIcon: Icon(icon, size: 20, color: primaryColor),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }
}
