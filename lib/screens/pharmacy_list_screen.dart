import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import 'pharmacy_store_screen.dart';

class PharmacyListScreen extends StatefulWidget {
  final Position userPos;
  const PharmacyListScreen({Key? key, required this.userPos}) : super(key: key);

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  List<dynamic> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndSortPharmacies();
  }

  // جلب البيانات وترتيبها حسب الأقرب
  _fetchAndSortPharmacies() async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}home_data.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List list = data['pharmacies'] ?? [];

        for (var p in list) {
          double lat = double.tryParse(p['Latitude']?.toString() ?? '0') ?? 0;
          double lng = double.tryParse(p['Longitude']?.toString() ?? '0') ?? 0;
          p['dist'] = Geolocator.distanceBetween(widget.userPos.latitude, widget.userPos.longitude, lat, lng) / 1000;
        }
        // الترتيب من الأقرب للأبعد
        list.sort((a, b) => (a['dist'] as double).compareTo(b['dist'] as double));

        if (mounted) setState(() { _pharmacies = list; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text("الصيدليات المتاحة", style: TextStyle(fontWeight: FontWeight.w900)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A7A48)))
          : _pharmacies.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _pharmacies.length,
                itemBuilder: (context, index) {
                  return _buildPharmacyCard(_pharmacies[index]);
                },
              ),
      ),
    );
  }

  // ==========================================
  // بناء كرت الصيدلية الاحترافي
  // ==========================================
  Widget _buildPharmacyCard(dynamic p) {
    // تجهيز البيانات مع حماية من الـ Null
    final String name = p['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String location = p['Location'] ?? 'العنوان غير متوفر';
    final String hours = p['WorkingHours'] ?? 'غير محددة';
    final String owner = "د. ${p['Fname'] ?? ''} ${p['Lname'] ?? ''}".trim();
    final String phone = p['Phone'] ?? 'لا يوجد هاتف';
    final double dist = p['dist'] ?? 0.0;
    final String logoUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/${p['Logo'] ?? 'default.png'}";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. القسم الأيمن: الشعار
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Center(
                          child: FaIcon(FontAwesomeIcons.hospital, color: Color(0xFF0A7A48), size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  // 2. القسم الأوسط: المعلومات الأساسية
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(LucideIcons.user, size: 13, color: Color(0xFF0A7A48)),
                            const SizedBox(width: 5),
                            Text(owner, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(LucideIcons.mapPin, size: 13, color: Colors.grey),
                            const SizedBox(width: 5),
                            Expanded(child: Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. القسم الأيسر: المسافة
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text("${dist.toStringAsFixed(1)} كم", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
            
            // 4. القسم السفلي: ساعات العمل والتواصل (رمادي فاتح)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              color: const Color(0xFFF8F9FA),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ساعات العمل
                  Row(
                    children: [
                      const Icon(LucideIcons.clock, size: 14, color: Colors.orange),
                      const SizedBox(width: 6),
                      Text(hours, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ],
                  ),
                  // رقم الهاتف
                  Row(
                    children: [
                      const Icon(LucideIcons.phone, size: 14, color: Color(0xFF0A7A48)),
                      const SizedBox(width: 6),
                      Text(phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54), textDirection: TextDirection.ltr),
                    ],
                  ),
                ],
              ),
            ),
            
            // 5. زر الدخول للمتجر
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => PharmacyStoreScreen(pharmacyId: int.parse(p['PharmacistID'].toString()), pharmacyName: name)));
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A7A48),
                ),
                child: const Center(
                  child: Text("تصفح الأدوية المتوفرة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.store, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text("لا توجد صيدليات قريبة حالياً", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}