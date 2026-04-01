import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';

import '../config/api_config.dart';
import 'map_picker_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final String currentAddress;
  final double? currentLat;
  final double? currentLng;

  const SavedAddressesScreen({super.key, required this.currentAddress, this.currentLat, this.currentLng});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late TextEditingController _addressController;
  double? _selectedLat;
  double? _selectedLng;
  bool _isSaving = false;
  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.currentAddress);
    _selectedLat = widget.currentLat;
    _selectedLng = widget.currentLng;
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.trim().isEmpty) {
      _showWarning('تنبيه', 'الرجاء كتابة وصف للعنوان.');
      return;
    }

    setState(() => _isSaving = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}update_patient_data.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "address": _addressController.text.trim(),
          "lat": _selectedLat,
          "lng": _selectedLng,
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
            desc: 'تم حفظ عنوان التوصيل الجديد بنجاح!',
            btnOkColor: primaryColor,
            btnOkOnPress: () => Navigator.pop(context, true),
          ).show();
        }
      }
    } catch (e) {
      _showWarning('خطأ', 'حدث خطأ في الاتصال بالسيرفر.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showWarning(String title, String desc) {
    AwesomeDialog(context: context, dialogType: DialogType.warning, title: title, desc: desc, btnOkColor: Colors.orange, btnOkOnPress: () {}).show();
  }

  @override
  Widget build(BuildContext context) {
    bool hasLocation = _selectedLat != null && _selectedLat != 0;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBF5),
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          title: const Text('العناوين المحفوظة', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(LucideIcons.arrowRight, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('وصف العنوان:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'مثال: نابلس - شارع رفيديا - عمارة الياسمين',
                        filled: true, fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text('الموقع الجغرافي:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const MapPickerScreen()));
                        if (result != null && result is LatLng) {
                          setState(() {
                            _selectedLat = result.latitude;
                            _selectedLng = result.longitude;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: hasLocation ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: hasLocation ? Colors.green.shade200 : Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(hasLocation ? LucideIcons.mapPin : LucideIcons.navigation, color: hasLocation ? Colors.green : Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(child: Text(hasLocation ? 'تم تحديد الموقع بنجاح' : 'اضغط لتحديد موقعك على الخريطة', style: TextStyle(fontWeight: FontWeight.bold, color: hasLocation ? Colors.green.shade700 : Colors.orange.shade700))),
                            const Icon(LucideIcons.chevronLeft, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ العنوان الجديد', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}