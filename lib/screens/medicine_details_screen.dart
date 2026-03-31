import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 💡 الأيقونات الطبية
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

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5); // مطابقة للويب

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          "${ApiConfig.baseUrl}medicine_details.php?id=${widget.medicineId}",
        ),
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. الهيدر الذي يحتوي على صورة الدواء
                  SliverToBoxAdapter(child: _buildHeaderImage()),

                  // 2. معلومات الدواء الأساسية
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMedicineInfo(),
                          const SizedBox(height: 25),
                          _buildDescriptionCard(),
                          const SizedBox(height: 35),
                          const Row(
                            children: [
                              FaIcon(
                                FontAwesomeIcons.houseMedicalCircleCheck,
                                color: Color(0xFF0A7A48),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "متوفر في الصيدليات التالية:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),

                  // 3. قائمة الصيدليات
                  _pharmacies.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                FaIcon(
                                  FontAwesomeIcons.boxOpen,
                                  size: 60,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 15),
                                const Text(
                                  "هذا الدواء غير متوفر في أي صيدلية حالياً",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) =>
                                _buildModernPharmacyCard(_pharmacies[index]),
                            childCount: _pharmacies.length,
                          ),
                        ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ), // مسافة سفلية
                ],
              ),
      ),
    );
  }

  // ==========================================
  // 🎨 تصميم رأس الصفحة (صورة الدواء)
  // ==========================================
  Widget _buildHeaderImage() {
    final String imageUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${_details['Image']}";

    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // صورة الدواء في المنتصف
            Center(
              child: Hero(
                tag: 'med_img_${widget.medicineId}', // حركة تنقل ناعمة للصورة
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => FaIcon(
                      FontAwesomeIcons.pills,
                      size: 100,
                      color: Colors.grey[200],
                    ),
                  ),
                ),
              ),
            ),

            // زر الرجوع
            Positioned(
              top: 10,
              right: 20,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.arrowRight,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🎨 تصميم معلومات الدواء
  // ==========================================
  Widget _buildMedicineInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _details['Name'],
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _details['ScientificName'] ?? "الاسم العلمي غير متوفر",
          style: const TextStyle(
            fontSize: 15,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        // الشارات (التصنيف + مراقب)
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            // شارة التصنيف
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(
                    FontAwesomeIcons.layerGroup,
                    size: 12,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _details['CategoryName'] ?? "عام",
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // شارة الأدوية المراقبة (Rx)
            if (_details['IsControlled'] == "1")
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.triangleExclamation,
                      size: 12,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Rx يلزم وصفة طبية",
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 🎨 كارت وصف الدواء
  // ==========================================
  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                "دواعي الاستعمال",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _details['Description'] ?? "لا يوجد وصف متوفر لهذا الدواء.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🎨 كارت الصيدلية (طريقة عرض عصرية)
  // ==========================================
  Widget _buildModernPharmacyCard(dynamic ph) {
    final String pharmacyName = ph['PharmacyName'] ?? 'صيدلية';
    final String location = ph['Location'] ?? 'غير متوفر';
    final double price = double.tryParse(ph['Price'].toString()) ?? 0.0;
    final int stock = int.tryParse(ph['Stock'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. معلومات الصيدلية
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: FaIcon(
                  FontAwesomeIcons.houseMedical,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // السعر
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${price.toStringAsFixed(2)} ₪",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: primaryColor,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stock > 5 ? "متوفر" : "باقي $stock",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: stock > 5 ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF0F0F0), height: 1),
          ),

          // 2. زر إضافة للسلة
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                try {
                  CartHelper.addToCart(
                    context: context,
                    stockId: int.parse(ph['StockID'].toString()),
                    systemMedId: widget.medicineId,
                    medicineName: _details['Name'],
                    image: _details['Image'] ?? 'default_med.png',
                    price: price,
                    pharmacistId: int.parse(ph['PharmacistID'].toString()),
                    pharmacyName: pharmacyName,
                    isControlled: _details['IsControlled'].toString() == "1",
                  );
                } catch (e) {
                  debugPrint("❌ خطأ في الإضافة للسلة: $e");
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
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.shoppingCart, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    "إضافة للسلة",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
