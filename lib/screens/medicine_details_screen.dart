import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/cart_helper.dart';

class MedicineDetailsScreen extends StatefulWidget {
  final int medicineId;
  final String medicineName;

  const MedicineDetailsScreen({
    super.key,
    required this.medicineId,
    required this.medicineName,
  });

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  bool _isLoading = true;
  dynamic _details;
  List<dynamic> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}medicine_details.php?id=${widget.medicineId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _details = data['details'];
            _pharmacies = data['pharmacies'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error details: $e");
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A7A48)))
            : CustomScrollView(
                slivers: [
                  // 1. هيدر يحتوي على الصورة وزر الرجوع
                  _buildSliverAppBar(),
                  
                  // 2. محتوى تفاصيل الدواء
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMedHeaderInfo(),
                          const SizedBox(height: 20),
                          _buildDescription(),
                          const SizedBox(height: 30),
                          const Text(
                            "الصيدليات المتوفر فيها الدواء:",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),

                  // 3. قائمة الصيدليات
                  _pharmacies.isEmpty
                      ? const SliverToBoxAdapter(child: Center(child: Text("غير متوفر في أي صيدلية حالياً")))
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildPharmacyCard(_pharmacies[index]),
                            childCount: _pharmacies.length,
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final String imageUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${_details['Image']}";
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF0A7A48),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowRight, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => Container(
            color: Colors.grey[200],
            child: const Icon(LucideIcons.pill, size: 100, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildMedHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _details['Name'],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ),
            if (_details['IsControlled'] == "1")
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                child: const Text("Rx مطلوب وصفة", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _details['ScientificName'] ?? "",
          style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Chip(
          label: Text(_details['CategoryName'] ?? "عام"),
          backgroundColor: const Color(0xFF0A7A48).withOpacity(0.1),
          labelStyle: const TextStyle(color: Color(0xFF0A7A48), fontWeight: FontWeight.bold),
          side: BorderSide.none,
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("عن هذا الدواء:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          _details['Description'] ?? "لا يوجد وصف متوفر لهذا الدواء.",
          style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPharmacyCard(dynamic ph) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF0A7A48).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_hospital, color: Color(0xFF0A7A48)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ph['PharmacyName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(ph['Location'], style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${ph['Price']} ₪", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0A7A48))),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  try {
                    debugPrint("🛒 محاولة إضافة للسلة: StockID=${ph['StockID']}, PharmacistID=${ph['PharmacistID']}, Price=${ph['Price']}");
                    CartHelper.addToCart(
                      context: context,
                      stockId: int.parse(ph['StockID'].toString()),
                      systemMedId: widget.medicineId,
                      medicineName: _details['Name'],
                      image: _details['Image'] ?? 'default_med.png',
                      price: double.parse(ph['Price'].toString()),
                      pharmacistId: int.parse(ph['PharmacistID'].toString()),
                      pharmacyName: ph['PharmacyName'],
                      isControlled: _details['IsControlled'].toString() == "1",
                    );
                  } catch (e) {
                    debugPrint("❌ خطأ في الإضافة للسلة: $e");
                    debugPrint("📦 بيانات الصيدلية المستلمة: $ph");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('خطأ في الإضافة: $e'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A7A48),
                  minimumSize: const Size(60, 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text("طلب", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}