import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

import 'map_picker_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  // متغيرات الإضافة
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  // متغيرات القائمة
  List<Map<String, dynamic>> _customAddresses = [];
  bool _isLoading = true;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // =====================================
  // 💡 دوال إضافة العنوان الجديد
  // =====================================
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

  Future<void> _saveAddress() async {
    if (_titleController.text.trim().isEmpty || _descController.text.trim().isEmpty) {
      _showError('تنبيه', 'الرجاء إدخال اسم العنوان والوصف.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showError('تنبيه', 'الرجاء تحديد الموقع على الخريطة.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      
      if (userId == null) return;

      List<String> savedAddresses = prefs.getStringList('custom_addresses_$userId') ?? [];

      Map<String, dynamic> newAddress = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': _titleController.text.trim(),
        'desc': _descController.text.trim(),
        'lat': _latitude,
        'lng': _longitude,
      };

      // 💡 إضافة العنوان الجديد في بداية القائمة (رقم 0) ليكون في الأعلى دائماً
      savedAddresses.insert(0, jsonEncode(newAddress));
      await prefs.setStringList('custom_addresses_$userId', savedAddresses);

      // تفريغ الحقول بعد الحفظ بنجاح
      _titleController.clear();
      _descController.clear();
      _latitude = null;
      _longitude = null;

      // إعادة تحميل القائمة
      await _loadAddresses();

      if (!mounted) return;
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        title: 'تم الحفظ',
        desc: 'تمت إضافة العنوان الجديد إلى قائمتك بنجاح.',
        btnOkColor: primaryColor,
        btnOkText: 'حسناً',
        btnOkOnPress: () {},
      ).show();
      
    } catch (e) {
      _showError('خطأ', 'حدث خطأ أثناء حفظ العنوان.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // =====================================
  // 💡 دوال جلب وحذف العناوين
  // =====================================
  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    
    if (userId != null) {
      List<String> savedList = prefs.getStringList('custom_addresses_$userId') ?? [];
      setState(() {
        _customAddresses = savedList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(int index) async {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'حذف العنوان؟',
      desc: 'هل أنت متأكد من حذف هذا العنوان من قائمتك؟',
      btnCancelOnPress: () {},
      btnCancelText: 'إلغاء',
      btnOkOnPress: () async {
        final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString('userId');
        if (userId != null) {
          _customAddresses.removeAt(index);
          List<String> stringList = _customAddresses.map((e) => jsonEncode(e)).toList();
          await prefs.setStringList('custom_addresses_$userId', stringList);
          setState(() {});
        }
      },
      btnOkText: 'نعم، احذف',
      btnOkColor: Colors.redAccent,
    ).show();
  }

  void _showError(String title, String desc) {
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
            'عناويني المحفوظة',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18),
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
                    // =====================================
                    // 1. قسم إضافة عنوان جديد
                    // =====================================
                    const Row(
                      children: [
                        Icon(LucideIcons.plusCircle, color: Color(0xFF0A7A48), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إضافة عنوان جديد',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _titleController,
                            label: 'اسم العنوان (مثال: المنزل، العمل)',
                            icon: LucideIcons.home,
                          ),
                          const Divider(color: Color(0xFFF0F0F0), height: 30),
                          _buildTextField(
                            controller: _descController,
                            label: 'العنوان الوصفي (المنطقة، الشارع، المعلم)',
                            icon: LucideIcons.alignRight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    GestureDetector(
                      onTap: _openMapPicker,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: _latitude != null ? Colors.green.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _latitude != null ? Colors.green : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _latitude != null ? LucideIcons.checkCircle2 : LucideIcons.map,
                              color: _latitude != null ? Colors.green : primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _latitude != null ? 'تم تحديد الموقع بنجاح' : 'حدد الموقع على الخريطة (GPS)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _latitude != null ? Colors.green : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.3),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('حفظ وإضافة', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // =====================================
                    // 2. قسم العناوين المحفوظة سابقاً
                    // =====================================
                    const Row(
                      children: [
                        Icon(LucideIcons.bookmark, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'العناوين المحفوظة سابقاً',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    if (_customAddresses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(LucideIcons.mapPinOff, size: 50, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text('لا توجد عناوين إضافية محفوظة', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customAddresses.length,
                        itemBuilder: (context, index) {
                          var address = _customAddresses[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                                  child: const Icon(LucideIcons.mapPin, color: Colors.blue),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(address['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.black87)),
                                      const SizedBox(height: 4),
                                      Text(address['desc'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteAddress(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
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