import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  // واجهة مبدئية فقط
  bool _hideOld = true;
  bool _hideNew = true;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F9),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 8, bottom: 12),
                child: Text(
                  'بيانات الدخول',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ),
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
                ),
                child: Column(
                  children: [
                    _buildCleanTextField(
                      'البريد الإلكتروني',
                      'muhammad.ali@example.com',
                      LucideIcons.mail,
                    ),
                    const Divider(color: Color(0xFFF0F0F0), height: 30),

                    // كلمة المرور الحالية
                    _buildCleanTextField(
                      'كلمة المرور الحالية',
                      '••••••••',
                      LucideIcons.lock,
                      isPassword: true,
                      isHidden: _hideOld,
                      onToggle: () {
                        setState(() {
                          _hideOld = !_hideOld;
                        });
                      },
                    ),
                    const Divider(color: Color(0xFFF0F0F0), height: 30),

                    // كلمة المرور الجديدة
                    _buildCleanTextField(
                      'كلمة المرور الجديدة',
                      '••••••••',
                      LucideIcons.key,
                      isPassword: true,
                      isHidden: _hideNew,
                      onToggle: () {
                        setState(() {
                          _hideNew = !_hideNew;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // لا يعمل حالياً
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'تحديث البيانات',
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
    IconData icon, {
    bool isPassword = false,
    bool isHidden = false,
    VoidCallback? onToggle,
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
          obscureText: isHidden,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, size: 20, color: Colors.black54),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isHidden ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 18,
                      color: Colors.grey,
                    ),
                    onPressed: onToggle,
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.only(top: 10),
          ),
        ),
      ],
    );
  }
}
