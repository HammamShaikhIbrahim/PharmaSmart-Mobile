import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import '../widgets/pharma_ui.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _prescriptions = [];

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}get_prescriptions.php?patient_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _prescriptions = data['prescriptions'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching prescriptions: $e");
      setState(() => _isLoading = false);
    }
  }

  // دالة لتكبير الصورة عند الضغط عليها
  void _showImageFullScreen(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // أداة تمكنك من عمل زووم للصورة بإصبعين
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(40),
                    child: const Icon(LucideIcons.imageOff, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.x, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
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
            'وصفاتي الطبية',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        body: _isLoading
            ? Center(child: PharmaUI.loader())
            : _prescriptions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final item = _prescriptions[index];
                      
                      // بناء الرابط بشكل آمن للعمل على الجوال بامتياز
                      String dbPath = item['ImagePath']?.toString() ?? '';
                      dbPath = dbPath.replaceAll('../', '').replaceFirst(RegExp(r'^/+'), '');
                      String baseClean = ApiConfig.baseUrl.replaceAll('api/', '');
                      if (!baseClean.endsWith('/')) baseClean += '/';
                      final String imageUrl = "$baseClean$dbPath";

                      final bool isVerified = item['IsVerified'].toString() == "1";
                      // 💡 جلب اسم الصيدلية من الـ API
                      final String pharmacyName = item['PharmacyName'] ?? 'صيدلية';
                      
                      // استخراج التاريخ والوقت بنظام 24 ساعة
                      DateTime parsedDate = DateTime.tryParse(item['OrderDate'].toString()) ?? DateTime.now();
                      String orderDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
                      String orderTime = "${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. البيانات على اليمين
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.fileText, color: Colors.indigo.shade400, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'طلب #ORD-${item['OrderID']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: Colors.black87,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // 💡 اسم الصيدلية
                                  Row(
                                    children: [
                                      Icon(LucideIcons.store, size: 14, color: primaryColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          pharmacyName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // التاريخ والوقت
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        orderDate,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        orderTime,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                        textDirection: TextDirection.ltr,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  
                                  // حالة الوصفة
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isVerified ? Colors.green.shade200 : Colors.orange.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified ? LucideIcons.checkCircle2 : LucideIcons.clock,
                                          size: 14,
                                          color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isVerified ? 'تم اعتماد الوصفة' : 'قيد المراجعة',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            // 2. الصورة على اليسار مع تصميم الـ Overlay للتكبير
                            GestureDetector(
                              onTap: () => _showImageFullScreen(imageUrl),
                              child: Container(
                                width: 95,
                                height: 110,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                  color: Colors.grey.shade50,
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  alignment: Alignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => const Center(
                                          child: Icon(LucideIcons.imageOff, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    // الطبقة الشفافة التي تحتوي على أيقونة التكبير
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          LucideIcons.zoomIn,
                                          color: Colors.white,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  // الإبقاء على الصفحة الفارغة الموحدة الفخمة
  Widget _buildEmptyState() {
    return PharmaUI.emptyState(
      icon: LucideIcons.fileText,
      title: 'لا توجد وصفات طبية',
      subtitle: 'لم تقم برفع أي وصفة طبية (روشتة) في طلباتك السابقة حتى الآن.',
    );
  }
}