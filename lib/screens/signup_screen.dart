import '../config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// استدعاء مكتبة المواقع الجغرافية
import 'package:latlong2/latlong.dart';
// استدعاء شاشة الخريطة التي صنعناها للتو
import 'map_picker_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _medicalHistoryController = TextEditingController();
  
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  // 💡 متغيرات الخريطة
  double? _latitude;
  double? _longitude;

  // دالة إرسال البيانات للسيرفر
  Future<void> _registerUser() async {
    if (_fnameController.text.isEmpty || _lnameController.text.isEmpty || 
        _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage("تنبيه", "الرجاء تعبئة جميع الحقول الأساسية (الاسم، الإيميل، كلمة المرور)", isError: true);
      return; 
    }

    // التحقق من أن المريض اختار موقعه
    if (_latitude == null || _longitude == null) {
      _showMessage("تنبيه", "الرجاء تحديد موقعك على الخريطة لتسهيل التوصيل", isError: true);
      return;
    }

    setState(() { _isLoading = true; });

    // 🚀 تم تصحيح اسم المجلد ليطابق htdocs الخاص بك (PharmaSmart_Web)
    final String apiUrl = "${ApiConfig.baseUrl}signup.php";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fname": _fnameController.text,
          "lname": _lnameController.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "phone": _phoneController.text,
          "address": _addressController.text,
          "dob": _dobController.text,
          "medicalHistory": _medicalHistoryController.text,
          "lat": _latitude.toString(), // إرسال الإحداثيات الفعلية
          "lng": _longitude.toString() // إرسال الإحداثيات الفعلية
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          _showMessage("نجاح", data['message'], isError: false, onSuccess: () {
            Navigator.pop(context); 
          });
        } else {
          _showMessage("خطأ", data['message'], isError: true);
        }
      } else {
        _showMessage("خطأ", "فشل الاتصال بالسيرفر. رمز الخطأ: ${response.statusCode}", isError: true);
      }
    } catch (e) {
      _showMessage("خطأ في الاتصال", "تأكد من تشغيل XAMPP ومن أن الـ IP واسم المجلد صحيح. التفاصيل: $e", isError: true);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _showMessage(String title, String message, {required bool isError, VoidCallback? onSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
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
              onPressed: () {
                Navigator.of(context).pop(); 
                if (onSuccess != null) onSuccess(); 
              },
              child: Text("حسناً", style: TextStyle(color: isError ? Colors.red : const Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0A7A48), onPrimary: Colors.white, onSurface: Colors.black),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // 💡 دالة لفتح الخريطة وانتظار الإحداثيات
  Future<void> _openMapPicker() async {
    // الانتقال لشاشة الخريطة وانتظار النتيجة (LatLng)
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    // إذا عاد المستخدم بموقع محدد، نقوم بحفظه وتحديث الشاشة
    if (pickedLocation != null) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowRight, color: Color(0xFF0A7A48)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children:[
                const Icon(LucideIcons.clipboardSignature, size: 60, color: Color(0xFF0A7A48)),
                const SizedBox(height: 10),
                const Text('إنشاء ملف صحي', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                const Text('يرجى تعبئة البيانات بدقة لضمان أفضل خدمة', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),

                _buildSectionTitle('معلومات الحساب الأساسية', LucideIcons.userCircle),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children: [
                      Row(
                        children:[
                          Expanded(child: _buildTextField(_fnameController, 'الاسم الأول', null)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildTextField(_lnameController, 'اسم العائلة', null)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_phoneController, 'رقم الهاتف', LucideIcons.phone, keyboardType: TextInputType.phone),
                      const SizedBox(height: 15),
                      _buildTextField(_emailController, 'البريد الإلكتروني', LucideIcons.mail, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 15),
                      _buildPasswordField(),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle('البيانات الشخصية والسكن', LucideIcons.home),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: Column(
                    children:[
                      TextField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        decoration: _inputDecoration('تاريخ الميلاد (سنة-شهر-يوم)', LucideIcons.calendar),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_addressController, 'العنوان الوصفي (المدينة - الشارع)', LucideIcons.map),
                      const SizedBox(height: 15),
                      
                      // 💡 تحديث تصميم زر الخريطة ليظهر إشارة "تم" إذا تم اختيار موقع
                      Container(
                        decoration: BoxDecoration(
                          color: _latitude != null ? Colors.green.withOpacity(0.1) : const Color(0xFF0A7A48).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: _latitude != null ? Colors.green : const Color(0xFF0A7A48).withOpacity(0.3)),
                        ),
                        child: ListTile(
                          leading: Icon(
                            _latitude != null ? LucideIcons.checkCircle2 : LucideIcons.mapPin, 
                            color: _latitude != null ? Colors.green : const Color(0xFF0A7A48)
                          ),
                          title: Text(
                            _latitude != null ? 'تم التقاط الموقع بنجاح!' : 'تحديد الموقع الجغرافي (GPS)', 
                            style: TextStyle(fontWeight: FontWeight.bold, color: _latitude != null ? Colors.green : const Color(0xFF0A7A48), fontSize: 14)
                          ),
                          subtitle: Text(
                            _latitude != null ? 'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}' : 'مطلوب لتسهيل توصيل الأدوية إليك', 
                            style: const TextStyle(fontSize: 11, color: Colors.grey)
                          ),
                          trailing: const Icon(LucideIcons.chevronLeft, color: Colors.grey),
                          onTap: _openMapPicker, // استدعاء دالة فتح الخريطة
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                _buildSectionTitle('التاريخ المرضي (اختياري)', LucideIcons.activity),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardDecoration(),
                  child: TextField(
                    controller: _medicalHistoryController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'هل تعاني من أمراض مزمنة؟ اكتب التفاصيل هنا لمساعدة الصيدلي...',
                      hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF0A7A48), width: 2)),
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                ElevatedButton(
                  onPressed: _isLoading ? null : _registerUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A7A48),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text('تسجيل الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Row(
        children:[
          Icon(icon, size: 20, color: const Color(0xFF0A7A48)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48))),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16.0),
      boxShadow:[BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 2))],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData? icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(controller: controller, keyboardType: keyboardType, decoration: _inputDecoration(label, icon));
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _isPasswordHidden,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF0A7A48)),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey),
          onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF0A7A48), width: 2)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF0A7A48)) : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: Color(0xFF0A7A48), width: 2)),
    );
  }
}