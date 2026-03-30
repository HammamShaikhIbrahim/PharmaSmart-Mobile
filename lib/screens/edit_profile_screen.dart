import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // واجهة مبدئية فقط
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
            'تعديل الملف الشخصي',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children:[
              // صورة البروفايل
              Center(
                child: Stack(
                  children:[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A7A48).withOpacity(0.1),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow:[
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                          ]
                      ),
                      child: const Center(child: Text('م', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48)))),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                        child: const Icon(LucideIcons.camera, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // الحقول داخل كارد أبيض
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children:[
                    _buildCleanTextField('الاسم الأول', 'محمد', LucideIcons.user),
                    const Divider(color: Color(0xFFF0F0F0), height: 30),
                    _buildCleanTextField('اسم العائلة', 'علي', LucideIcons.user),
                    const Divider(color: Color(0xFFF0F0F0), height: 30),
                    _buildCleanTextField('رقم الهاتف', '0599123456', LucideIcons.phone),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // زر الحفظ (شكل فقط)
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('حفظ التغييرات', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanTextField(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            prefixIcon: Icon(icon, size: 20, color: Colors.black54),
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