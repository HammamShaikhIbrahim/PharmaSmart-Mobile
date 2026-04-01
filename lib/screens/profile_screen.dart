import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_sheet.dart'; 
import 'medical_history_screen.dart'; 
import 'my_prescriptions_screen.dart'; 
import 'saved_addresses_screen.dart'; 
import 'payment_methods_screen.dart'; 

const Color kPrimary = Color(0xFF0A7A48);
const Color kBgColor = Color(0xFFF2FBF5);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fname = '', _lname = '', _email = '', _phone = '';
  String _dob = '', _address = '', _medicalHistory = '';
  double? _lat, _lng;

  bool _loading = true;
  bool _isGuest = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;

    if (_isGuest) {
      setState(() => _loading = false);
      return;
    }

    String? userId = prefs.getString('userId');
    if (userId != null) {
      try {
        final res = await http.get(
          Uri.parse("${ApiConfig.baseUrl}get_profile.php?user_id=$userId"),
        );
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['status'] == 'success') {
            setState(() {
              _fname = data['data']['Fname'] ?? 'مستخدم';
              _lname = data['data']['Lname'] ?? '';
              _email = data['data']['Email'] ?? '';
              _phone = data['data']['Phone'] ?? 'غير محدد';
              _dob = data['data']['DOB'] ?? 'غير محدد';
              _address = data['data']['Address'] ?? 'غير محدد';
              _medicalHistory = data['data']['MedicalHistory'] ?? '';
              _lat = data['data']['Latitude'] != null ? double.tryParse(data['data']['Latitude'].toString()) : null;
              _lng = data['data']['Longitude'] != null ? double.tryParse(data['data']['Longitude'].toString()) : null;
              _loading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
    setState(() => _loading = false);
  }

  String get _initials {
    if (_fname.isEmpty) return 'م';
    String f = _fname.isNotEmpty ? _fname[0] : '';
    String l = _lname.isNotEmpty ? _lname[0] : '';
    return '$f $l'.trim();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تسجيل الخروج', textAlign: TextAlign.right, style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        content: const Text('هل أنت متأكد أنك تريد الخروج من حسابك؟', textAlign: TextAlign.right),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('خروج', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (ok == true && mounted) {
      final p = await SharedPreferences.getInstance();
      await p.clear();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: kBgColor, body: Center(child: CircularProgressIndicator(color: kPrimary)));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBgColor,
        body: Stack(
          children: [
            // خلفية تجريدية
            Positioned(top: -80, right: -50, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.05)))),
            Positioned(top: 150, left: -100, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.03)))),
            Positioned(bottom: -50, right: -80, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.04)))),

            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: Text('حسابي', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87))),
                          const SizedBox(height: 25),

                          // 💡 بطاقة المستخدم (تعديل الترتيب ليصبح من اليمين لليسار)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
                            child: Row(
                              children: [
                                // 1. اليمين: الصورة الرمزية
                                Container(
                                  width: 65, height: 65,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.withOpacity(0.1), border: Border.all(color: Colors.white, width: 3), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
                                  child: Center(child: Text(_initials, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kPrimary))),
                                ),
                                const SizedBox(width: 15),
                                // 2. المنتصف: البيانات نصية (محاذاة لليمين)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('$_fname $_lname', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                                      const SizedBox(height: 2),
                                      Text(_email, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                // 3. اليسار: قلم التعديل
                                IconButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())).then((_) => _fetchProfileData()),
                                  icon: const Icon(LucideIcons.edit2, color: Colors.black87, size: 22),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          _buildSectionTitle('المعلومات الشخصية', LucideIcons.contact, Colors.blue),
                          _buildCard([
                            _buildInfoRow(LucideIcons.phone, 'رقم الهاتف', _phone, Colors.green),
                            _buildInfoRow(LucideIcons.calendar, 'تاريخ الميلاد', _dob, Colors.orange),
                            _buildInfoRow(LucideIcons.mapPin, 'العنوان', _address, Colors.redAccent, isLast: true),
                          ]),
                          const SizedBox(height: 25),

                          _buildSectionTitle('نشاطي', LucideIcons.activity, Colors.redAccent),
                          _buildCard([
                            _buildActionRow(LucideIcons.stethoscope, 'السجل المرضي', Colors.red, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalHistoryScreen(currentHistory: _medicalHistory))).then((value) {
                                if (value == true) _fetchProfileData();
                              });
                            }),
                            _buildActionRow(LucideIcons.shoppingBag, 'الطلبات السابقة', Colors.teal, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyOrdersScreen()));
                            }),
                            _buildActionRow(LucideIcons.fileText, 'وصفاتي الطبية', Colors.indigo, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPrescriptionsScreen()));
                            }),
                            _buildPaymentMethodRow(),
                            _buildActionRow(LucideIcons.bookmark, 'العناوين المحفوظة', Colors.purple, isLast: true, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => SavedAddressesScreen(currentAddress: _address, currentLat: _lat, currentLng: _lng))).then((value) {
                                if (value == true) _fetchProfileData();
                              });
                            }),
                          ]),
                          const SizedBox(height: 25),

                          _buildSectionTitle('الإعدادات', LucideIcons.settings, Colors.grey.shade700),
                          _buildCard([
                            _buildActionRow(LucideIcons.bell, 'الإشعارات', Colors.amber.shade600, onTap: () {
                              NotificationsSheet.show(context);
                            }),
                            _buildActionRow(LucideIcons.shieldCheck, 'الخصوصية والأمان', Colors.green.shade700, onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                            }),
                            _buildSoonRow(LucideIcons.moon, 'الوضع الليلي', Colors.indigo.shade900),
                            _buildSoonRow(LucideIcons.globe, 'تغيير اللغة', Colors.lightBlue),
                            // 💡 زر الخروج: تم تمرير hideArrow: true لإزالة السهم
                            _buildActionRow(LucideIcons.logOut, 'تسجيل الخروج', Colors.redAccent, isLast: true, textColor: Colors.redAccent, hideArrow: true, onTap: _logout),
                          ]),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value, Color iconColor, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(value, textAlign: TextAlign.left, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String title, Color iconColor, {bool isLast = false, Color? textColor, bool hideArrow = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : BorderRadius.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 15),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor ?? Colors.black87)),
            const Spacer(),
            if (!hideArrow) const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSoonRow(IconData icon, String title, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor.withOpacity(0.5)),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black54)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade200)),
            child: const Text('قريباً', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodRow() {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))),
        child: Row(
          children: [
            const Icon(LucideIcons.creditCard, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 15),
            const Text('طريقة الدفع', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black87)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.green.shade200)), child: const Text('COD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green))),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.orange.shade200)), child: const Text('Visa قريباً', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange))),
            const SizedBox(width: 10),
            const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}