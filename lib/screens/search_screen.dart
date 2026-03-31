import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'medicine_details_screen.dart';
import '../services/cart_helper.dart'; // 💡 استدعاء السلة

class SearchScreen extends StatefulWidget {
  final int? initialCategoryId;
  final String? categoryName;
  final Position? userPos;

  const SearchScreen({
    super.key,
    this.initialCategoryId,
    this.categoryName,
    this.userPos,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _results = [];
  List<dynamic> _categories = [];

  bool _isLoading = false;
  bool _isLoadingCategories = true;

  String _sortBy = 'price';
  late int _selectedCategoryId;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? 0;
    _fetchCategories();
    _fetchResults();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}home_data.php"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _categories = data['categories'] ?? [];
            _isLoadingCategories = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _fetchResults({String query = ''}) async {
    setState(() {
      _isLoading = true;
    });

    double lat = widget.userPos?.latitude ?? 0;
    double lng = widget.userPos?.longitude ?? 0;

    String url =
        "${ApiConfig.baseUrl}search_medicines.php?query=$query&category_id=$_selectedCategoryId&sort_by=$_sortBy&lat=$lat&lng=$lng";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _results = data['results'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching medicines: $e");
      setState(() => _isLoading = false);
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
          title: const Text(
            "البحث والأدوية",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(
                    LucideIcons.arrowRight,
                    color: Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => _fetchResults(query: val),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن دواء، مادة فعالة...',
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
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _sortBy = 'price');
                            _fetchResults(query: _searchController.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sortBy == 'price'
                                  ? primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _sortBy == 'price'
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "السعر (الأقل أولاً)",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _sortBy == 'price'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _sortBy = 'distance');
                            _fetchResults(query: _searchController.text);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _sortBy == 'distance'
                                  ? primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _sortBy == 'distance'
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "الصيدليات الأقرب",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _sortBy == 'distance'
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!_isLoadingCategories && _categories.isNotEmpty)
              Container(
                height: 50,
                color: Colors.white,
                width: double.infinity,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  children: [
                    _buildCategoryChip(id: 0, name: "الكل"),
                    ..._categories.map(
                      (cat) => _buildCategoryChip(
                        id: int.parse(cat['CategoryID'].toString()),
                        name: cat['NameAR'],
                      ),
                    ),
                  ],
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
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _results.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _results.length,
                      itemBuilder: (context, index) =>
                          _buildModernResultCard(_results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({required int id, required String name}) {
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategoryId = id);
        _fetchResults(query: _searchController.text);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.black54,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 💡 تصميم الكارت المطابق تماماً لمتجر الصيدلية
  // ==========================================
  Widget _buildModernResultCard(dynamic item) {
    final String imageUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item['Image']}";
    final bool showDistance = _sortBy == 'distance' && item['Distance'] != null;
    final bool isControlled = item['IsControlled'].toString() == "1";
    final int stockCount = int.tryParse(item['Stock'].toString()) ?? 0;
    final double price = double.tryParse(item['Price'].toString()) ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => MedicineDetailsScreen(
            medicineId: int.parse(item['SystemMedID'].toString()),
            medicineName: item['MedName'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. النصوص على اليمين (RTL)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['MedName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['ScientificName'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['CategoryName'] ?? 'غير مصنف',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.houseMedical,
                                  size: 10,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item['PharmacyName'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$price ₪',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: primaryColor,
                            ),
                            textDirection: TextDirection.ltr,
                          ),

                          if (showDistance)
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.mapPin,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "${item['Distance']} كم",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              stockCount > 5 ? "متوفر" : "باقي $stockCount",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: stockCount > 5
                                    ? Colors.green
                                    : Colors.redAccent,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),

                // 2. الصورة على اليسار (RTL)
                Stack(
                  children: [
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Center(
                            child: FaIcon(
                              FontAwesomeIcons.pills,
                              color: Colors.grey.shade300,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isControlled)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Rx",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 💡 زر إضافة للسلة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  try {
                    CartHelper.addToCart(
                      context: context,
                      // 💡 التعديل الجذري هنا (أصبح يأخذ الـ StockID الحقيقي القادم من الداتابيز)
                      stockId: int.parse(item['StockID'].toString()),
                      systemMedId: int.parse(item['SystemMedID'].toString()),
                      medicineName: item['MedName'],
                      image: item['Image'] ?? 'default_med.png',
                      price: price,
                      pharmacistId: int.parse(item['PharmacistID'].toString()),
                      pharmacyName: item['PharmacyName'],
                      isControlled: isControlled,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.shoppingCart,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "إضافة للسلة",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
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
        children: [
          FaIcon(
            FontAwesomeIcons.magnifyingGlassChart,
            size: 70,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 15),
          const Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'حاول البحث باسم مختلف أو اختر تصنيفاً آخر',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
