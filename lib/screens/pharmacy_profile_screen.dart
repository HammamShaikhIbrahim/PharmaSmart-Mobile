import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // 💡 مكتبة فتح الاتصال والخرائط
import 'package:geolocator/geolocator.dart'; // 💡 مكتبة حساب المسافة
import '../config/api_config.dart';
import 'pharmacy_store_screen.dart';

class PharmacyProfileScreen extends StatelessWidget {
  final dynamic pharmacyData;
  final Position? userPos; // 💡 أضفنا موقع المستخدم لنحسب المسافة بدقة

  const PharmacyProfileScreen({Key? key, required this.pharmacyData, this.userPos}) : super(key: key);

  // ==========================================
  // 💡 دوال تفعيل الأزرار (الاتصال + الخريطة)
  // ==========================================
  
  // دالة الاتصال الهاتفي
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  // دالة فتح خرائط جوجل (Google Maps)
  Future<void> _openGoogleMaps(double lat, double lng) async {
    // رابط يفتح خرائط جوجل مباشرة على موقع الصيدلية
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    final Uri launchUri = Uri.parse(googleMapsUrl);
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri, mode: LaunchMode.externalApplication); // يفتح التطبيق الخارجي
    }
  }

  @override
  Widget build(BuildContext context) {
    // تجهيز البيانات
    final String name = pharmacyData['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String doctor = "د. ${pharmacyData['Fname'] ?? ''} ${pharmacyData['Lname'] ?? ''}".trim();
    final String phone = pharmacyData['Phone'] ?? '';
    final String location = pharmacyData['Location'] ?? 'العنوان غير متوفر';
    final String hours = (pharmacyData['WorkingHours'] != null && pharmacyData['WorkingHours'].toString().trim().isNotEmpty) ? pharmacyData['WorkingHours'] : 'ساعات العمل غير محددة';
    
    // 💡 حساب المسافة الدقيق هنا!
    double dist = 0.0;
    double pLat = double.tryParse(pharmacyData['Latitude']?.toString() ?? '0') ?? 0;
    double pLng = double.tryParse(pharmacyData['Longitude']?.toString() ?? '0') ?? 0;
    
    if (userPos != null && pLat != 0) {
      dist = Geolocator.distanceBetween(userPos!.latitude, userPos!.longitude, pLat, pLng) / 1000;
    } else if (pharmacyData['dist'] != null) {
      dist = pharmacyData['dist'];
    }
    
    final String logoName = pharmacyData['Logo']?.toString() ?? '';
    final bool hasLogo = logoName.isNotEmpty && logoName != 'default.png';
    final String logoUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/$logoName";
    
    final Color primaryColor = const Color(0xFF0A7A48);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        
        // زر المتجر العائم
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyStoreScreen(
                    pharmacyId: int.parse(pharmacyData['PharmacistID'].toString()),
                    pharmacyName: name,
              )));
            },
            icon: const Icon(LucideIcons.store, color: Colors.white),
            label: const Text("تصفح أدوية الصيدلية والمتاجر", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              shadowColor: primaryColor.withOpacity(0.5),
            ),
          ),
        ),

        body: SingleChildScrollView(
          child: Column(
            children: [
              // ==========================================
              // 🎨 1. الغلاف الهندسي المبهر (Geometric Cover)
              // ==========================================
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // الحاوية الخضراء المنحنية
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0A7A48), Color(0xFF0F9D58)], // تدرج لوني فخم
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 🎨 الدوائر الهندسية الشفافة المتداخلة (لإعطاء طابع عصري جداً)
                          Positioned(
                            top: -40,
                            right: -30,
                            child: CircleAvatar(radius: 90, backgroundColor: Colors.white.withOpacity(0.08)),
                          ),
                          Positioned(
                            bottom: -50,
                            left: -20,
                            child: CircleAvatar(radius: 70, backgroundColor: Colors.white.withOpacity(0.08)),
                          ),
                          Positioned(
                            top: 50,
                            left: 50,
                            child: CircleAvatar(radius: 20, backgroundColor: Colors.white.withOpacity(0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // زر العودة فوق الغلاف
                  Positioned(
                    top: 50,
                    right: 20,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(LucideIcons.arrowRight, color: Colors.white, size: 20),
                      ),
                    ),
                  ),

                  // اللوجو البارز المرتفع قليلاً عن الغلاف
                  Positioned(
                    bottom: -50,
                    child: Container(
                      width: 110,
                      height: 110,
                      padding: const EdgeInsets.all(4), 
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hasLogo ? Colors.white : primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: hasLogo
                              ? Image.network(logoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildFallbackLogo(primaryColor))
                              : _buildFallbackLogo(primaryColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // ==========================================
              // 2. معلومات الصيدلية الأساسية
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.center),
                    const SizedBox(height: 5),
                    if (doctor.length > 3)
                      Text(doctor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 15),

                    // كرت المسافة فقط (تمت إزالة "مفتوح الآن" بناءً على طلبك)
                    if (dist > 0)
                      _buildTag(LucideIcons.mapPin, "تبعد عنك ${dist.toStringAsFixed(1)} كم", Colors.blue),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // 💡 3. أزرار التواصل (تم برمجتها لتعمل فعلياً!)
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCircleAction(LucideIcons.phoneCall, "اتصال", primaryColor, () {
                    if (phone.isNotEmpty) {
                      _makePhoneCall(phone);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رقم الهاتف غير متوفر')));
                    }
                  }),
                  const SizedBox(width: 30),
                  _buildCircleAction(LucideIcons.map, "الاتجاهات", Colors.orange, () {
                    if (pLat != 0) {
                      _openGoogleMaps(pLat, pLng);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الموقع الجغرافي غير متوفر')));
                    }
                  }),
                ],
              ),

              const SizedBox(height: 30),

              // ==========================================
              // 4. تفاصيل العمل (كروت المعلومات)
              // ==========================================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("معلومات التواصل والعمل", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    const SizedBox(height: 15),
                    _buildInfoCard(LucideIcons.mapPin, "العنوان التفصيلي", location, primaryColor),
                    const SizedBox(height: 15),
                    _buildInfoCard(LucideIcons.clock, "ساعات الدوام", hours, Colors.orange),
                    const SizedBox(height: 15),
                    _buildInfoCard(LucideIcons.phone, "رقم التواصل", phone.isNotEmpty ? phone : 'لا يوجد', primaryColor, isPhone: true),
                    
                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------
  // دوال مساعدة 
  // ------------------------------------------

  Widget _buildFallbackLogo(Color color) {
    return Center(child: FaIcon(FontAwesomeIcons.prescriptionBottleMedical, color: color, size: 40));
  }

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))],
              border: Border.all(color: color.withOpacity(0.1)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle, Color color, {bool isPhone = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87), textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}