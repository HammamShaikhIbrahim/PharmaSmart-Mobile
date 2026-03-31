import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import '../services/cart_helper.dart';
import 'medicine_details_screen.dart';

class PharmacyStoreScreen extends StatefulWidget {
  final int pharmacyId;
  final String pharmacyName;
  const PharmacyStoreScreen({
    super.key,
    required this.pharmacyId,
    required this.pharmacyName,
  });

  @override
  State<PharmacyStoreScreen> createState() => _PharmacyStoreScreenState();
}

class _PharmacyStoreScreenState extends State<PharmacyStoreScreen> {
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  List<String> _categories = [];

  bool _loading = true;
  String _selectedCategory = "الكل";
  final TextEditingController _searchController = TextEditingController();

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    try {
      final res = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}pharmacy_inventory.php?pharmacy_id=${widget.pharmacyId}",
        ),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _allItems = data['items'] ?? [];
        _filteredItems = List.from(_allItems);

        Set<String> uniqueCategories = {"الكل"};
        for (var item in _allItems) {
          uniqueCategories.add(item['CategoryName'] ?? 'غير مصنف');
        }
        _categories = uniqueCategories.toList();

        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterItems() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = _allItems.where((item) {
        bool matchesSearch =
            item['Name'].toString().toLowerCase().contains(query) ||
            (item['ScientificName'] ?? '').toString().toLowerCase().contains(
              query,
            );
        bool matchesCategory =
            _selectedCategory == "الكل" ||
            (item['CategoryName'] ?? 'غير مصنف') == _selectedCategory;

        return matchesSearch && matchesCategory;
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
          backgroundColor: Colors.white,
          elevation: 0,
          title: Column(
            children: [
              Text(
                widget.pharmacyName,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const Text(
                "تصفح متجر الصيدلية",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _filterItems(),
                decoration: InputDecoration(
                  hintText: 'ابحث في هذه الصيدلية...',
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
            if (!_loading && _categories.length > 1)
              Container(
                height: 50,
                color: Colors.white,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) =>
                      _buildCategoryChip(_categories[index]),
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
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) =>
                          _buildModernResultCard(_filteredItems[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String catName) {
    bool isSelected = _selectedCategory == catName;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = catName);
        _filterItems();
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
            catName,
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
  // 💡 تصميم الكارت المطابق لصورة (Lyrica) 100%
  // ==========================================
  Widget _buildModernResultCard(dynamic item) {
    final String imageUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item['Image']}";
    final bool isControlled = item['IsControlled'].toString() == "1";
    final int stockCount = int.tryParse(item['Stock'].toString()) ?? 0;
    final double price = double.tryParse(item['Price'].toString()) ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => MedicineDetailsScreen(
            medicineId: int.parse(item['SystemMedID'].toString()),
            medicineName: item['Name'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16), // زيادة التباعد الداخلي
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24), // حواف أكثر نعومة
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
                      // الاسم التجاري
                      Text(
                        item['Name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // الاسم العلمي
                      Text(
                        item['ScientificName'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // التصنيف + الصيدلية
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item['CategoryName'] ?? 'غير مصنف',
                              style: TextStyle(
                                fontSize: 10,
                                color: primaryColor,
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
                                    widget.pharmacyName,
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

                      // السعر والتوفر (السعر يمين، متوفر يسار)
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

            // زر إضافة للسلة
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  try {
                    CartHelper.addToCart(
                      context: context,
                      stockId: int.parse(item['StockID'].toString()),
                      systemMedId: int.parse(item['SystemMedID'].toString()),
                      medicineName: item['Name'],
                      image: item['Image'] ?? 'default_med.png',
                      price: price,
                      pharmacistId: widget.pharmacyId,
                      pharmacyName: widget.pharmacyName,
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
            'لا توجد منتجات مطابقة',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
