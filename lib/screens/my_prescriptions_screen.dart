import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class MyPrescriptionsScreen extends StatefulWidget {
  const MyPrescriptionsScreen({super.key});

  @override
  State<MyPrescriptionsScreen> createState() => _MyPrescriptionsScreenState();
}

class _MyPrescriptionsScreenState extends State<MyPrescriptionsScreen> {
  bool _isLoading = true;
  List<dynamic> _prescriptions = [];

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
        Uri.parse("${ApiConfig.baseUrl}patient_orders.php?patient_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List orders = data['orders'];
          setState(() {
            // جلب الطلبات التي تحتوي على مسار صورة صحيح فقط
            _prescriptions = orders
                .where((o) =>
                    o['PrescriptionImage'] != null &&
                    o['PrescriptionImage'].toString().length > 5)
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (context, error, stackTrace) => _buildErrorCard(isModal: true),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(LucideIcons.xCircle, color: Colors.white, size: 35),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard({bool isModal = false}) {
    return Container(
      height: isModal ? 300 : 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.imageOff, size: isModal ? 60 : 40, color: Colors.grey.shade400),
          const SizedBox(height: 15),
          const Text('الصورة غير متوفرة', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          const Text('تأكد من وجود الملف في السيرفر', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
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
          title: const Text('وصفاتي الطبية', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(icon: const Icon(LucideIcons.arrowRight, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A7A48)))
            : _prescriptions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.fileX, size: 70, color: Colors.grey.shade300),
                        const SizedBox(height: 15),
                        const Text('لا توجد وصفات طبية محفوظة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _prescriptions.length,
                    itemBuilder: (context, index) {
                      final p = _prescriptions[index];

                      // 💡 إصلاح بناء الرابط ليحذف "api/" ويضيف مسار الصورة بشكل صحيح
                      String rootUrl = ApiConfig.baseUrl.split('api/')[0];
                      String dbPath = p['PrescriptionImage'].toString();
                      if (dbPath.startsWith('/')) dbPath = dbPath.substring(1);
                      
                      final String imageUrl = "$rootUrl$dbPath";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(LucideIcons.fileText, color: Colors.indigo.shade400, size: 20),
                                      const SizedBox(width: 10),
                                      Text('مرفقة مع طلب #${p['OrderID']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                                    ],
                                  ),
                                  Text(p['OrderDate'].toString().split(' ')[0], style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12), textDirection: TextDirection.ltr),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _showImageDialog(imageUrl),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      height: 200,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => _buildErrorCard(),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                                    child: const Icon(LucideIcons.zoomIn, color: Colors.white),
                                  ),
                                ],
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
}