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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  String _userId = '';

  // 💡 متغيرات لحفظ القيم الأصلية
  String _originalEmail = '';
  String _originalPhone = '';
  bool _hasChanges = false;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _loadCurrentData();

    // 💡 إضافة مستمعات للحقول لتفعيل الزر عند أي تغيير
    _emailController.addListener(_checkIfChanged);
    _phoneController.addListener(_checkIfChanged);
    _newPassController.addListener(_checkIfChanged);
    _confirmPassController.addListener(_checkIfChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_checkIfChanged);
    _phoneController.removeListener(_checkIfChanged);
    _newPassController.removeListener(_checkIfChanged);
    _confirmPassController.removeListener(_checkIfChanged);

    _emailController.dispose();
    _phoneController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // 💡 دالة فحص التغييرات
  void _checkIfChanged() {
    if (_emailController.text.trim() != _originalEmail ||
        _phoneController.text.trim() != _originalPhone ||
        _newPassController.text.isNotEmpty ||
        _confirmPassController.text.isNotEmpty) {
      if (!_hasChanges) setState(() => _hasChanges = true);
    } else {
      if (_hasChanges) setState(() => _hasChanges = false);
    }
  }

  Future<void> _loadCurrentData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId') ?? '';

    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}get_profile.php?user_id=$_userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          _originalEmail = data['data']['Email'] ?? '';
          _originalPhone = data['data']['Phone'] ?? '';

          _emailController.text = _originalEmail;
          _phoneController.text = _originalPhone;
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });
  }

  void _onSaveClicked() {
    if (_newPassController.text.isNotEmpty) {
      if (_newPassController.text != _confirmPassController.text) {
        _showWarning('عدم تطابق', 'كلمة المرور الجديدة غير مطابقة لتأكيد كلمة المرور.');
        return;
      }
    }

    _showPasswordPrompt();
  }

  void _showPasswordPrompt() {
    _oldPassController.clear();
    bool hideOldPass = true; 

    AwesomeDialog(
      context: context,
      dialogType: DialogType.infoReverse,
      animType: AnimType.scale,
      body: StatefulBuilder(builder: (context, setStateDialog) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            children: [
              const Text(
                'تأكيد الهوية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                'يرجى إدخال كلمة المرور الحالية لتأكيد حفظ التعديلات وحماية حسابك.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _oldPassController,
                obscureText: hideOldPass,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'كلمة المرور الحالية',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                  prefixIcon: Icon(LucideIcons.unlock, color: primaryColor, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(hideOldPass ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey, size: 18),
                    onPressed: () {
                      setStateDialog(() {
                        hideOldPass = !hideOldPass;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      btnCancelOnPress: () {},
      btnCancelText: 'إلغاء',
      btnCancelColor: Colors.grey.shade400,
      btnOkOnPress: () {
        if (_oldPassController.text.isEmpty) {
          _showWarning('تنبيه', 'لم تقم بإدخال كلمة المرور!');
        } else {
          _executeSecurityUpdate(); 
        }
      },
      btnOkText: 'تأكيد وحفظ',
      btnOkColor: primaryColor,
    ).show();
  }

  Future<void> _executeSecurityUpdate() async {
    setState(() => _isSaving = true);

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}update_security.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": _userId,
          "email": _emailController.text.trim(),
          "phone": _phoneController.text.trim(),
          "old_pass": _oldPassController.text,
          "new_pass": _newPassController.text.isEmpty ? null : _newPassController.text,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم التحديث',
            desc: 'تم تحديث بيانات الأمان بنجاح!',
            btnOkColor: primaryColor,
            btnOkText: 'ممتاز',
            dismissOnTouchOutside: false,
            btnOkOnPress: () => Navigator.pop(context, true),
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

  void _showWarning(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: title,
      desc: desc,
      btnOkColor: Colors.orange,
      btnOkText: 'حسناً',
      btnOkOnPress: () {},
    ).show();
  }

  void _deleteAccountDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'تحذير خطير!',
      desc: 'هل أنت متأكد أنك تريد حذف حسابك نهائياً؟ ستفقد جميع بياناتك وطلباتك السابقة.',
      btnCancelOnPress: () {},
      btnCancelText: 'إلغاء',
      btnCancelColor: Colors.grey.shade400,
      btnOkColor: Colors.redAccent,
      btnOkText: 'نعم، أريد الحذف',
      btnOkOnPress: () {
        AwesomeDialog(
          context: context,
          dialogType: DialogType.info,
          title: 'إجراء أمني',
          desc: 'لأسباب أمنية وللحفاظ على سجلات الطلبات الطبية، يرجى التواصل مع الإدارة الفنية لحذف حسابك بشكل نهائي من قاعدة البيانات.',
          btnOkColor: primaryColor,
          btnOkText: 'حسناً',
        ).show();
      },
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
            'الخصوصية والأمان',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 90,
                        height: 90,
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
                          child: Icon(LucideIcons.shieldCheck, size: 40, color: primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildSectionHeader('بيانات الاتصال والأمان', LucideIcons.mail, Colors.blue),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildCleanField(
                            'البريد الإلكتروني',
                            LucideIcons.mail,
                            _emailController,
                          ),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanField(
                            'رقم الهاتف',
                            LucideIcons.phone,
                            _phoneController,
                            isPhone: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    _buildSectionHeader('تغيير كلمة المرور', LucideIcons.key, Colors.orange),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          _buildCleanField(
                            'كلمة المرور الجديدة (اتركه فارغاً إذا لا تريد تغييره)',
                            LucideIcons.lock,
                            _newPassController,
                            isPassword: true,
                            isHidden: _hideNew,
                            onToggle: () => setState(() => _hideNew = !_hideNew),
                          ),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildCleanField(
                            'تأكيد كلمة المرور الجديدة',
                            LucideIcons.lock,
                            _confirmPassController,
                            isPassword: true,
                            isHidden: _hideConfirm,
                            onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 💡 زر الحفظ يعتمد على حالة _hasChanges
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (_hasChanges && !_isSaving) ? _onSaveClicked : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _hasChanges ? primaryColor : Colors.grey.shade300,
                          disabledBackgroundColor: Colors.grey.shade300,
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
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : Text(
                                'حفظ التحديثات',
                                style: TextStyle(
                                  color: _hasChanges ? Colors.white : Colors.grey.shade500,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    _buildSectionHeader('خيارات الأمان', LucideIcons.alertTriangle, Colors.redAccent),
                    InkWell(
                      onTap: _deleteAccountDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: _cardDecoration(),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'حذف الحساب',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.redAccent),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'حذف حسابك نهائياً من النظام',
                                    style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      border: Border.all(color: Colors.grey.shade100),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCleanField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isHidden = false,
    bool isPhone = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        TextField(
          controller: controller,
          obscureText: isHidden,
          textAlign: isPhone ? TextAlign.left : TextAlign.right,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: primaryColor),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(isHidden ? LucideIcons.eyeOff : LucideIcons.eye, size: 18, color: Colors.grey),
                    onPressed: onToggle,
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
          ),
        ),
      ],
    );
  }
}