import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:latlong2/latlong.dart';

import '../config/api_config.dart';
import 'pharmacy_store_screen.dart';
import 'pharmacy_profile_screen.dart'; 
import '../widgets/pharma_ui.dart';

class PharmacyListScreen extends StatefulWidget {
  final Position userPos;
  const PharmacyListScreen({super.key, required this.userPos});

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  List<Map<String, dynamic>> _pharmacies = [];
  List<Map<String, dynamic>> _filteredPharmacies = []; 
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _fetchAndSortPharmacies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSortPharmacies() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}home_data.php"),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> rawList = data['pharmacies'] ?? [];
        List<Map<String, dynamic>> mutableList = rawList
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        for (var p in mutableList) {
          double lat = double.tryParse(p['Latitude']?.toString() ?? '0') ?? 0;
          double lng = double.tryParse(p['Longitude']?.toString() ?? '0') ?? 0;

          p['dist'] = Geolocator.distanceBetween(
                widget.userPos.latitude,
                widget.userPos.longitude,
                lat,
                lng,
              ) /
              1000;
        }

        mutableList.sort(
          (a, b) => (a['dist'] as num).compareTo(b['dist'] as num),
        );

        if (mounted) {
          setState(() {
            _pharmacies = mutableList;
            _filteredPharmacies = mutableList; 
            _loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ حدث خطأ أثناء جلب الصيدليات: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  // 💡 التعديل هنا: تخصيص البحث ليتم فقط عبر اسم الصيدلية
  void _filterPharmacies(String query) {
    final String lowerQuery = query.toLowerCase();
    setState(() {
      _filteredPharmacies = _pharmacies.where((p) {
        final name = (p['PharmacyName'] ?? '').toString().toLowerCase();
        
        return name.contains(lowerQuery); // البحث بالاسم فقط
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text(
            "الصيدليات المتاحة",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: TextField(
                controller: _searchController,
                onChanged: _filterPharmacies,
                decoration: InputDecoration(
                  hintText: 'ابحث عن صيدلية بالاسم...', // 💡 تم تعديل النص ليعكس أن البحث بالاسم فقط
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  prefixIcon: Icon(LucideIcons.search, color: primaryColor),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            
            Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.03), Colors.transparent],
                ),
              ),
            ),

            Expanded(
              child: _loading
                  ? PharmaUI.loader()
                  : _filteredPharmacies.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredPharmacies.length,
                          itemBuilder: (context, index) {
                            return _buildPharmacyCard(_filteredPharmacies[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyCard(Map<String, dynamic> p) {
    final String name = p['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String location = p['Location'] ?? 'العنوان غير متوفر';
    final String hours = (p['WorkingHours'] != null &&
            p['WorkingHours'].toString().trim().isNotEmpty)
        ? p['WorkingHours']
        : 'ساعات العمل غير محددة';
    final String owner = "${p['Fname'] ?? ''} ${p['Lname'] ?? ''}".trim();
    final double dist = p['dist'] ?? 0.0;

    final String logoName = p['Logo']?.toString() ?? '';
    final bool hasLogo = logoName.isNotEmpty && logoName != 'default.png';
    final String logoUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/$logoName";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
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
                    color: Colors.white,
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
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${dist.toStringAsFixed(1)} كم",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.user,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            owner,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hours,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PharmacyStoreScreen(
                              pharmacyId: int.parse(
                                p['PharmacistID'].toString(),
                              ),
                              pharmacyName: name,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Row(
                        children: [
                          Text(
                            "تصفح",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PharmacyProfileScreen(
                              pharmacyData: p,
                              userPos: widget.userPos,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        minimumSize: Size.zero,
                        side: BorderSide(color: primaryColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.info, 
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),

                    OutlinedButton(
                      onPressed: () {
                        double lat =
                            double.tryParse(p['Latitude']?.toString() ?? '0') ??
                                0;
                        double lng = double.tryParse(
                              p['Longitude']?.toString() ?? '0',
                            ) ??
                            0;
                        Navigator.pop(context, LatLng(lat, lng));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(10),
                        minimumSize: Size.zero,
                        side: BorderSide(color: primaryColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.mapPin,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Opacity(
      opacity: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildEmptyState() {
    return PharmaUI.emptyState(
      icon: LucideIcons.searchX,
      title: 'لا توجد نتائج',
      subtitle: 'لم يتم العثور على أي صيدلية بهذا الاسم.',
    );
  }
}