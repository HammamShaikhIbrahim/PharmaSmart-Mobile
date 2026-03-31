import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
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
  final TextEditingController _medicalHistoryController =
      TextEditingController();

  bool _isPasswordHidden = true;
  bool _isLoading = false;

  double? _latitude;
  double? _longitude;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  Future<void> _registerUser() async {
    if (_fnameController.text.isEmpty ||
        _lnameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showError("تنبيه", "الرجاء تعبئة جميع الحقول الأساسية");
      return;
    }

    if (_latitude == null || _longitude == null) {
      _showError("تنبيه", "الرجاء تحديد موقعك على الخريطة لتسهيل التوصيل");
      return;
    }

    setState(() => _isLoading = true);

    final String apiUrl = "${ApiConfig.baseUrl}signup.php";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fname": _fnameController.text,
          "lname": _lnameController.text,
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
          "phone": _phoneController.text,
          "address": _addressController.text,
          "dob": _dobController.text,
          "medicalHistory": _medicalHistoryController.text,
          "lat": _latitude.toString(),
          "lng": _longitude.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: "اكتمل التسجيل",
            desc: data['message'],
            btnOkColor: primaryColor,
            btnOkText: "ممتاز",
            btnOkOnPress: () => Navigator.pop(context),
          ).show();
        } else {
          _showError("خطأ", data['message']);
        }
      } else {
        _showError("خطأ", "فشل الاتصال بالسيرفر");
      }
    } catch (e) {
      _showError("خطأ في الاتصال", "تأكد من اتصالك بالإنترنت");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: title,
      desc: desc,
      btnOkColor: Colors.redAccent,
      btnOkText: "حسناً",
      btnOkOnPress: () {},
    ).show();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? pickedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );
    if (pickedLocation != null) {
      setState(() {
        _latitude = pickedLocation.latitude;
        _longitude = pickedLocation.longitude;
      });
    }
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
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // الهيدر
              FaIcon(
                FontAwesomeIcons.clipboardUser,
                size: 60,
                color: primaryColor,
              ),
              const SizedBox(height: 10),
              const Text(
                'إنشاء ملف صحي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const Text(
                'يرجى تعبئة البيانات بدقة لضمان أفضل خدمة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // كارت البيانات الأساسية
              _buildSectionTitle(
                'معلومات الحساب الأساسية',
                LucideIcons.userCircle,
              ),
              _buildCardContainer([
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _fnameController,
                        'الاسم الأول',
                        null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        _lnameController,
                        'اسم العائلة',
                        null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  _emailController,
                  'البريد الإلكتروني',
                  LucideIcons.mail,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                _buildTextField(
                  _phoneController,
                  'رقم الهاتف',
                  LucideIcons.phone,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 15),
                _buildPasswordField(),
              ]),
              const SizedBox(height: 25),

              // كارت العنوان
              _buildSectionTitle('العنوان وتحديد الموقع', LucideIcons.map),
              _buildCardContainer([
                _buildTextField(
                  _addressController,
                  'المدينة - الحي - الشارع',
                  LucideIcons.mapPin,
                ),
                const SizedBox(height: 15),

                // زر تحديد الموقع الذكي
                GestureDetector(
                  onTap: _openMapPicker,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: _latitude != null
                          ? Colors.green.withOpacity(0.1)
                          : primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _latitude != null
                            ? Colors.green
                            : primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _latitude != null
                              ? LucideIcons.checkCircle2
                              : LucideIcons.navigation,
                          color: _latitude != null
                              ? Colors.green
                              : primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _latitude != null
                                    ? 'تم تحديد الموقع الجغرافي بنجاح'
                                    : 'اضغط لتحديد موقعك الجغرافي (GPS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _latitude != null
                                      ? Colors.green
                                      : primaryColor,
                                ),
                              ),
                              if (_latitude != null)
                                Text(
                                  'إحداثيات: ${_latitude!.toStringAsFixed(4)} , ${_longitude!.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const Icon(
                          LucideIcons.chevronLeft,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 25),

              // كارت التاريخ المرضي
              _buildSectionTitle(
                'التاريخ المرضي (اختياري)',
                LucideIcons.activity,
              ),
              _buildCardContainer([
                TextField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration(
                    'تاريخ الميلاد',
                    LucideIcons.calendar,
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _medicalHistoryController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'هل تعاني من حساسية معينة أو أمراض مزمنة؟...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
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
              ]),
              const SizedBox(height: 35),

              // زر التسجيل
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
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
                        'تسجيل الحساب',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData? icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _isPasswordHidden,
      decoration: InputDecoration(
        hintText: 'كلمة المرور',
        prefixIcon: Icon(LucideIcons.lock, color: primaryColor, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordHidden ? LucideIcons.eyeOff : LucideIcons.eye,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _isPasswordHidden = !_isPasswordHidden),
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: primaryColor, size: 20)
          : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor),
      ),
    );
  }
}
