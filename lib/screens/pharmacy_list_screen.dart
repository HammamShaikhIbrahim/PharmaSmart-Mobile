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
  const PharmacyListScreen({super.key, required this.userPos});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  List<dynamic> _pharmacies = [];
  bool _loading = true;
  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    _fetchAndSortPharmacies();
  }

  Future<void> _fetchAndSortPharmacies() async {
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
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _pharmacies.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(15),
                physics: const BouncingScrollPhysics(),
                itemCount: _pharmacies.length,
                itemBuilder: (context, index) {
                  return _buildPharmacyCard(_pharmacies[index]);
                },
              ),
      ),
    );
  }

  Widget _buildPharmacyCard(dynamic p) {
    final String name = p['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String location = p['Location'] ?? 'العنوان غير متوفر';
    final String hours = (p['WorkingHours'] != null && p['WorkingHours'].toString().trim().isNotEmpty) ? p['WorkingHours'] : 'ساعات العمل غير محددة';
    final String owner = "${p['Fname'] ?? ''} ${p['Lname'] ?? ''}".trim();
    final String phone = p['Phone'] ?? 'لا يوجد هاتف';
    final double dist = p['dist'] ?? 0.0;
    
    final String logoName = p['Logo']?.toString() ?? '';
    final bool hasLogo = logoName.isNotEmpty;
    final String logoUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/$logoName";
    

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: hasLogo ? Colors.white : primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: hasLogo
                        ? Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => _buildFallbackLogo(),
                          )
                        : _buildFallbackLogo(),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                            child: Text("${dist.toStringAsFixed(1)} كم", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(owner, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade100, thickness: 1.5),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.clock, size: 14, color: Colors.orange),
                          const SizedBox(width: 6),
                          Expanded(child: Text(hours, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.phone, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Text(phone, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87), textDirection: TextDirection.ltr),
                        ],
                      ),
                    ],
                  ),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => PharmacyStoreScreen(pharmacyId: int.parse(p['PharmacistID'].toString()), pharmacyName: name)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Row(
                    children: [
                      Text("تصفح الصيدلية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowLeft, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 💡 الأيقونة الاحتياطية الجديدة (زجاجة دواء / صيدلية)
  Widget _buildFallbackLogo() {
    return const Center(
      child: FaIcon(FontAwesomeIcons.prescriptionBottleMedical, color: Color(0xFF0A7A48), size: 30),
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