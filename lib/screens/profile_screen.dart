import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../config/api_config.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_sheet.dart';
import 'medical_history_screen.dart';
import 'prescriptions_screen.dart';
import 'payment_methods_screen.dart'; // 💡 استدعاء شاشة طرق الدفع الجديدة

const Color kPrimary = Color(0xFF0A7A48);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fname = '', _lname = '', _email = '', _phone = '';
  String _dob = '', _address = '', _medicalHistory = '';
  bool _loading = true;
  bool _darkMode = false;
  bool _isGuest = false;

  final Color bgColor = const Color(0xFFF2FBF5); // 💡 اللون الموحد للتطبيق

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // جلب البيانات الحقيقية من السيرفر
  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;
    _darkMode = prefs.getBool('dark_mode') ?? false;

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
    final f = _fname.isNotEmpty ? _fname[0] : '';
    final l = _lname.isNotEmpty ? _lname[0] : '';
    return '$f$l'.toUpperCase();
  }

  // دالة إظهار "قريباً" للأشياء التي طلبناها
  void _showComingSoon(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkColor: kPrimary,
      btnOkText: 'حسناً',
    ).show();
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.right,
          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد أنك تريد الخروج من حسابك؟',
          textAlign: TextAlign.right,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text(
              'خروج',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (ok == true && mounted) {
      final p = await SharedPreferences.getInstance();
      await p.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_isGuest) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.userX, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 20),
              const Text(
                'أنت تتصفح كضيف',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
                child: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'حسابي',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      _buildProfileHeaderCard(),
                      const SizedBox(height: 30),

                      // 1. المعلومات الشخصية
                      _buildSectionTitle(
                        'المعلومات الشخصية',
                        LucideIcons.contact,
                        Colors.blueAccent,
                      ),
                      _buildGlassCard([
                        _buildListItem(
                          icon: LucideIcons.phone,
                          title: 'رقم الهاتف',
                          trailingText: _phone,
                          iconColor: Colors.green,
                          showArrow: false,
                        ),
                        _buildListItem(
                          icon: LucideIcons.calendar,
                          title: 'تاريخ الميلاد',
                          trailingText: _dob,
                          iconColor: Colors.orange,
                          showArrow: false,
                        ),
                        _buildListItem(
                          icon: LucideIcons.mapPin,
                          title: 'العنوان',
                          trailingText: _address, 
                          iconColor: Colors.redAccent,
                          showArrow: false,
                          isLast: true,
                        ),
                      ]),
                      const SizedBox(height: 25),

                      // 2. نشاطي
                      _buildSectionTitle(
                        'نشاطي',
                        LucideIcons.activity,
                        Colors.redAccent,
                      ),
                      _buildGlassCard([
                        _buildListItem(
                          icon: LucideIcons.stethoscope,
                          title: 'السجل المرضي',
                          iconColor: Colors.red,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicalHistoryScreen(
                                currentHistory: _medicalHistory,
                              ),
                            ),
                          ).then((_) => _fetchProfileData()), 
                        ),
                        _buildListItem(
                          icon: LucideIcons.shoppingBag,
                          title: 'الطلبات السابقة',
                          iconColor: Colors.teal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const MyOrdersScreen(),
                            ),
                          ),
                        ),
                        _buildListItem(
                          icon: LucideIcons.fileText,
                          title: 'وصفاتي الطبية',
                          iconColor: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PrescriptionsScreen(),
                            ),
                          ),
                        ),
                        _buildPaymentMethodItem(), // 💡 تم التعديل على هذا العنصر في الأسفل
                        _buildListItem(
                          icon: LucideIcons.bookmark,
                          title: 'العناوين المحفوظة',
                          iconColor: Colors.purple,
                          isLast: true,
                          onTap: () => _showComingSoon(
                            'عناويني',
                            'قريباً ستتمكن من إضافة أكثر من عنوان (منزل، عمل) لسرعة التوصيل.',
                          ),
                        ),
                      ]),
                      const SizedBox(height: 25),

                      // 3. الإعدادات
                      _buildSectionTitle(
                        'الإعدادات',
                        LucideIcons.settings,
                        Colors.grey.shade700,
                      ),
                      _buildGlassCard([
                        _buildListItem(
                          icon: LucideIcons.bell,
                          title: 'الإشعارات',
                          iconColor: Colors.amber.shade600,
                          onTap: () => NotificationsSheet.show(context),
                        ),
                        _buildListItem(
                          icon: LucideIcons.globe,
                          title: 'تغيير اللغة',
                          trailingText: 'العربية',
                          iconColor: Colors.lightBlue,
                          onTap: () => _showComingSoon(
                            'تغيير اللغة',
                            'دعم اللغة الإنجليزية قادم في التحديثات القادمة.',
                          ),
                        ),
                        _buildListItem(
                          icon: LucideIcons.moon,
                          title: 'الوضع الليلي',
                          iconColor: Colors.indigo.shade900,
                          showArrow: false,
                          trailingWidget: Switch(
                            value: _darkMode,
                            activeColor: kPrimary,
                            onChanged: (v) async {
                              setState(() => _darkMode = v);
                              final p =
                                  await SharedPreferences.getInstance();
                              await p.setBool('dark_mode', v);
                            },
                          ),
                        ),
                        _buildListItem(
                          icon: LucideIcons.shieldCheck,
                          title: 'الخصوصية والأمان',
                          iconColor: Colors.green.shade700,
                          isLast: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecurityScreen(),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 25),

                      // 4. تسجيل الخروج
                      _buildGlassCard([
                        _buildListItem(
                          icon: LucideIcons.logOut,
                          title: 'تسجيل الخروج',
                          titleColor: Colors.redAccent,
                          iconColor: Colors.redAccent,
                          showArrow: false,
                          isLast: true,
                          onTap: _logout,
                        ),
                      ]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================
  // Widgets التصميم
  // =====================================

  Widget _buildProfileHeaderCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimary.withOpacity(0.1),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Center(
                  child: Text(
                    _initials,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_fname $_lname',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // زر التعديل (ينعش البيانات بعد العودة)
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => _fetchProfileData()),
                icon: const Icon(LucideIcons.edit3, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? trailingText,
    Widget? trailingWidget,
    bool showArrow = true,
    bool isLast = false,
    Color? titleColor,
    Color? iconColor,
    VoidCallback? onTap,
    bool isLtr = false,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? Colors.black54),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ),
            if (trailingText != null)
              Expanded(
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (trailingWidget != null) trailingWidget,
            if (trailingWidget == null && showArrow)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  LucideIcons.chevronLeft,
                  size: 18,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 💡 تم تعديل هذا الجزء ليقوم بنقلك لشاشة طرق الدفع
  Widget _buildPaymentMethodItem() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaymentMethodsScreen(),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.creditCard,
              size: 20,
              color: Colors.blueGrey,
            ),
            const SizedBox(width: 15),
            const Text(
              'طريقة الدفع',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Text(
                'COD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Text(
                'Visa قريباً',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}