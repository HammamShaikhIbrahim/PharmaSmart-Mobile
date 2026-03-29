import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // مسافة
import '../config/api_config.dart';
import 'medicine_details_screen.dart';

class SearchScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? categoryName;
  final Position? userPos; // نحتاج الموقع للفلترة

  const SearchScreen({Key? key, this.initialCategoryId, this.categoryName, this.userPos}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _results =[];
  bool _isLoading = false;
  String _sortBy = 'price'; // الفلتر الافتراضي

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    // البحث التلقائي عند فتح الشاشة
    _fetchResults(catId: widget.initialCategoryId);
  }

  Future<void> _fetchResults({String query = '', int? catId}) async {
    setState(() { _isLoading = true; });
    
    int categoryToSearch = catId ?? widget.initialCategoryId ?? 0;
    double lat = widget.userPos?.latitude ?? 0;
    double lng = widget.userPos?.longitude ?? 0;

    String url = "${ApiConfig.baseUrl}search_medicines.php?query=$query&category_id=$categoryToSearch&sort_by=$_sortBy&lat=$lat&lng=$lng";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['results'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(
            widget.categoryName != null ? "${widget.categoryName}" : "جميع الأدوية",
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children:[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children:[
                  // شريط البحث المتبقي (للبحث داخل التصنيف أو العام)
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _fetchResults(query: val),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن دواء، مادة فعالة...',
                      prefixIcon: Icon(LucideIcons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // 💡 أزرار الفلترة (الأرخص / الأقرب)
                  Row(
                    children:[
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() { _sortBy = 'price'; });
                            _fetchResults(query: _searchController.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sortBy == 'price' ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _sortBy == 'price' ? Colors.transparent : Colors.grey.shade300),
                            ),
                            child: Center(child: Text("السعر (الأقل أولاً)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _sortBy == 'price' ? Colors.white : Colors.black87))),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() { _sortBy = 'distance'; });
                            _fetchResults(query: _searchController.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sortBy == 'distance' ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _sortBy == 'distance' ? Colors.transparent : Colors.grey.shade300),
                            ),
                            child: Center(child: Text("الصيدليات الأقرب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _sortBy == 'distance' ? Colors.white : Colors.black87))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // قائمة النتائج
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _results.length,
                          itemBuilder: (context, index) => _buildResultCard(_results[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Icon(LucideIcons.searchX, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          const Text('لا توجد نتائج مطابقة', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic item) {
    final String imageUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item['Image']}";
    final bool showDistance = _sortBy == 'distance' && item['Distance'] != null;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MedicineDetailsScreen(medicineId: int.parse(item['SystemMedID'].toString()), medicineName: item['MedName']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children:[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[100], width: 70, height: 70, child: const Icon(LucideIcons.pill, color: Colors.grey))),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['MedName'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 5),
                  Row(
                    children:[
                      Icon(Icons.local_hospital, size: 12, color: primaryColor),
                      const SizedBox(width: 5),
                      Expanded(child: Text(item['PharmacyName'], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  if (showDistance) ...[
                    const SizedBox(height: 4),
                    Text("تبعد ${item['Distance']} كم", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                  ]
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${item['Price']} ₪', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryColor), textDirection: TextDirection.ltr),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(LucideIcons.arrowLeft, color: primaryColor, size: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}