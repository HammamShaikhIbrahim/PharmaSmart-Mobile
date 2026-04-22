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

  bool _isLoading = true;
  bool _isSaving = false;
  String _userId = '';

  // 💡 متغيرات لحفظ القيم الأصلية لمقارنتها بالتعديلات
  String _originalFname = '';
  String _originalLname = '';
  bool _hasChanges = false;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // 💡 إضافة مستمعات للحقول لتفعيل الزر فقط عند التغيير
    _fnameController.addListener(_checkIfChanged);
    _lnameController.addListener(_checkIfChanged);
  }

  @override
  void dispose() {
    _fnameController.removeListener(_checkIfChanged);
    _lnameController.removeListener(_checkIfChanged);
    _fnameController.dispose();
    _lnameController.dispose();
    super.dispose();
  }

  // 💡 دالة فحص التغييرات
  void _checkIfChanged() {
    if (_fnameController.text.trim() != _originalFname ||
        _lnameController.text.trim() != _originalLname) {
      if (!_hasChanges) setState(() => _hasChanges = true);
    } else {
      if (_hasChanges) setState(() => _hasChanges = false);
    }
  }

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
            _originalFname = data['data']['Fname'] ?? '';
            _originalLname = data['data']['Lname'] ?? '';
            
            _fnameController.text = _originalFname;
            _lnameController.text = _originalLname;
            
            _isLoading = false;
            _hasChanges = false; // تهيئة الحالة بعد التحميل
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading profile data: $e");
      setState(() => _isLoading = false);
    }
  }

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
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
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
              Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
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
                    const SizedBox(height: 20),
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 💡 زر الحفظ يعتمد على قيمة _hasChanges
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_hasChanges && !_isSaving) ? _updateProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges ? primaryColor : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300, // اللون الرمادي عند التعطيل
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: _hasChanges ? 5 : 0,
                          shadowColor: _hasChanges ? primaryColor.withOpacity(0.3) : Colors.transparent,
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
                            : Text(
                                'حفظ التغييرات',
                                style: TextStyle(
                                  color: _hasChanges ? Colors.white : Colors.grey.shade500, // لون النص رمادي غامق عند التعطيل
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
    TextEditingController controller,
  ) {
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
          textAlign: TextAlign.right,
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