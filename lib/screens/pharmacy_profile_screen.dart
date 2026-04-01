import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'pharmacy_store_screen.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

class PharmacyProfileScreen extends StatelessWidget {
  final dynamic pharmacyData;
  final Position? userPos;

  const PharmacyProfileScreen({
    super.key,
    required this.pharmacyData,
    this.userPos,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = pharmacyData['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String doctor =
        "${pharmacyData['Fname'] ?? ''} ${pharmacyData['Lname'] ?? ''}".trim();
    final String phone = pharmacyData['Phone'] ?? '';
    final String location = pharmacyData['Location'] ?? 'العنوان غير متوفر';
    final String hours =
        (pharmacyData['WorkingHours'] != null &&
            pharmacyData['WorkingHours'].toString().trim().isNotEmpty)
        ? pharmacyData['WorkingHours']
        : 'ساعات العمل غير محددة';

    double dist = 0.0;
    double pLat =
        double.tryParse(pharmacyData['Latitude']?.toString() ?? '0') ?? 0;
    double pLng =
        double.tryParse(pharmacyData['Longitude']?.toString() ?? '0') ?? 0;

    if (userPos != null && pLat != 0) {
      dist =
          Geolocator.distanceBetween(
            userPos!.latitude,
            userPos!.longitude,
            pLat,
            pLng,
          ) /
          1000;
    } else if (pharmacyData['dist'] != null) {
      dist = pharmacyData['dist'];
    }

    final String logoName = pharmacyData['Logo']?.toString() ?? '';
    final bool hasLogo = logoName.isNotEmpty && logoName != 'default.png';
    final String logoUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/$logoName";

    final Color primaryColor = const Color(0xFF0A7A48);
    final Color bgColor = const Color(0xFFF2FBF5); // 💡 ثيم التطبيق الموحد

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "معلومات الصيدلية",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PharmacyStoreScreen(
                    pharmacyId: int.parse(
                      pharmacyData['PharmacistID'].toString(),
                    ),
                    pharmacyName: name,
                  ),
                ),
              );
            },
            icon: const Icon(LucideIcons.store, color: Colors.white),
            label: const Text(
              "تصفح أدوية الصيدلية",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: primaryColor.withOpacity(0.4),
            ),
          ),
        ),

        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 💡 كرت المعلومات الأساسي (نظيف ومتناسق)
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // اللوجو
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: hasLogo
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => _buildFallbackLogo(),
                              )
                            : _buildFallbackLogo(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "د. $doctor",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (dist > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "تبعد عنك ${dist.toStringAsFixed(1)} كم",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 💡 أزرار التواصل (تصميم جديد)
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      LucideIcons.phone,
                      "اتصال بالصيدلية",
                      primaryColor,
                      () {
                        if (phone.isNotEmpty) {
                          _makePhoneCall(phone);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('رقم الهاتف غير متوفر'),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildActionBtn(
                      LucideIcons.messageCircle, // أيقونة المحادثة الموحدة
                      "استشارة طبية",
                      Colors.orange.shade600,
                      () {
                        // 💡 استدعاء الدالة الفخمة الموحدة
                        _showComingSoonMsg(context, "المحادثات المباشرة");
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 💡 تفاصيل العمل
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      LucideIcons.mapPin,
                      "العنوان",
                      location,
                      isLast: false,
                    ),
                    _buildInfoTile(
                      LucideIcons.clock,
                      "ساعات الدوام",
                      hours,
                      isLast: false,
                    ),
                    _buildInfoTile(
                      LucideIcons.phone,
                      "رقم التواصل",
                      phone.isNotEmpty ? phone : 'لا يوجد',
                      isLast: true,
                      isPhone: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 اللوجو الخاص بك كبديل هنا أيضاً
  Widget _buildFallbackLogo() {
    return Opacity(
      opacity: 0.4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
    );
  }

  // 💡 الدالة الموحدة لإظهار رسالة "قريباً" بنفس التصميم الفخم
  void _showComingSoonMsg(BuildContext context, String featureName) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      customHeader: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
      title: 'ميزة $featureName',
      desc:
          'هذه الميزة قيد التطوير حالياً، وتعمل فرقنا على تجهيزها بأفضل شكل لتكون متاحة في التحديث القادم!',
      btnOkOnPress: () {},
      btnOkColor: const Color(0xFF0A7A48),
      btnOkText: 'فهمت ذلك',
      buttonsBorderRadius: BorderRadius.circular(15),
      descTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
    ).show();
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String subtitle, {
    required bool isLast,
    bool isPhone = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A7A48).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF0A7A48), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  textDirection: isPhone
                      ? TextDirection.ltr
                      : TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
