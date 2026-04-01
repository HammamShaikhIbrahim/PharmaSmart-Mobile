import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../config/api_config.dart';

class MedicalHistoryScreen extends StatefulWidget {
  final String currentHistory;

  const MedicalHistoryScreen({super.key, required this.currentHistory});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late TextEditingController _historyController;
  bool _isSaving = false;
  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    _historyController = TextEditingController(text: widget.currentHistory);
  }

  @override
  void dispose() {
    _historyController.dispose();
    super.dispose();
  }

  Future<void> _saveHistory() async {
    setState(() => _isSaving = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}update_patient_data.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "medical_history": _historyController.text.trim(),
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم الحفظ',
            desc: 'تم تحديث سجلك المرضي بنجاح!',
            btnOkColor: primaryColor,
            btnOkText: 'حسناً',
            btnOkOnPress: () {
              Navigator.pop(context, true); // إرجاع true لتحديث البروفايل
            },
          ).show();
        }
      }
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        title: 'خطأ',
        desc: 'حدث خطأ في الاتصال، حاول مرة أخرى.',
        btnOkColor: Colors.red,
        btnOkText: 'حسناً',
        btnOkOnPress: () {},
      ).show();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBF5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('السجل المرضي', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                          child: Icon(LucideIcons.stethoscope, color: Colors.red.shade400, size: 24),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Text(
                            'تاريخك الطبي والأمراض المزمنة',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Divider(color: Colors.black12, height: 1),
                    ),
                    const Text(
                      'يرجى كتابة أي أمراض مزمنة تعاني منها، أو حساسية تجاه أدوية معينة ليكون الصيدلي على علم بها قبل صرف العلاج.',
                      style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _historyController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: 'مثال: أعاني من حساسية البنسلين، ومريض سكري من النوع الثاني...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.3),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('حفظ السجل المرضي', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}