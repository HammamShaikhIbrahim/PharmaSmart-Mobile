import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../config/api_config.dart';
import 'pharmacy_store_screen.dart';

class PharmacyProfileScreen extends StatelessWidget {
  final dynamic pharmacyData;

  const PharmacyProfileScreen({Key? key, required this.pharmacyData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String name = pharmacyData['PharmacyName'] ?? 'صيدلية غير معروفة';
    final String doctor = "د. ${pharmacyData['Fname'] ?? ''} ${pharmacyData['Lname'] ?? ''}".trim();
    final String phone = pharmacyData['Phone'] ?? 'لا يوجد رقم تواصل';
    final String location = pharmacyData['Location'] ?? 'العنوان غير متوفر';
    final String logoUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/logos/${pharmacyData['Logo']}";
    
    final Color primaryColor = const Color(0xFF0A7A48);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children:[
              Container(
                width: 120, height: 120,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipOval(
                  child: Image.network(
                    logoUrl, fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Center(child: FaIcon(FontAwesomeIcons.hospital, size: 50, color: primaryColor)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87), textAlign: TextAlign.center),
              const SizedBox(height: 5),
              if (doctor.length > 3)
                Text(doctor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              
              const SizedBox(height: 30),

              _buildInfoCard(LucideIcons.mapPin, "العنوان", location, primaryColor),
              const SizedBox(height: 15),
              _buildInfoCard(LucideIcons.phone, "رقم التواصل", phone, primaryColor, isPhone: true),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PharmacyStoreScreen(
                        pharmacyId: int.parse(pharmacyData['PharmacistID'].toString()),
                        pharmacyName: name,
                      ),
                    ),
                  );
                },
                icon: const Icon(LucideIcons.pill, color: Colors.white),
                label: const Text("تصفح أدوية الصيدلية", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle, Color primaryColor, {bool isPhone = false}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children:[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  subtitle, 
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87),
                  textDirection: isPhone ? TextDirection.ltr : TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}