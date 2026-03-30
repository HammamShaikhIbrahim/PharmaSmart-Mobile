import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'edit_profile_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // بيانات وهمية للعرض المبدئي (UI Only)
  final String _fullName = "محمد علي";
  final String _email = "muhammad.ali@example.com";
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // لون خلفية فاتح جداً مائل للبنفسجي/الأزرق كما في الصورة
        backgroundColor: const Color(0xFFF4F4F9),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'حسابي',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              // 1. بطاقة المستخدم العلوية
              _buildUserHeaderCard(),
              const SizedBox(height: 20),

              // 2. بطاقة العضوية (مطابقة لـ Gold Membership بالصورة)
              _buildHealthMembershipCard(),
              const SizedBox(height: 25),

              // 3. قسم المعلومات الشخصية
              _buildSectionTitle('المعلومات الشخصية'),
              _buildCardSection([
                _buildListTile(LucideIcons.user, 'اسم المستخدم', trailingText: '@muhammad_ali'),
                _buildListTile(LucideIcons.phone, 'رقم الهاتف', trailingText: '0599123456'),
                _buildListTile(LucideIcons.calendar, 'تاريخ الميلاد', trailingText: '1995-08-15'),
                _buildListTile(LucideIcons.mapPin, 'العنوان', trailingText: 'غزة - الرمال', isLast: true),
              ]),
              const SizedBox(height: 25),

              // 4. قسم نشاطي
              _buildSectionTitle('نشاطي'),
              _buildCardSection([
                _buildListTile(LucideIcons.activity, 'عرض السجل المرضي'),
                _buildListTile(LucideIcons.shoppingBag, 'الطلبات السابقة'),
                _buildListTile(LucideIcons.fileText, 'الوصفات الطبية'),
                _buildListTile(LucideIcons.creditCard, 'طريقة الدفع'),
                _buildListTile(LucideIcons.bookmark, 'العناوين المحفوظة', isLast: true),
              ]),
              const SizedBox(height: 25),

              // 5. قسم الإعدادات
              _buildSectionTitle('الإعدادات'),
              _buildCardSection([
                _buildListTile(LucideIcons.bell, 'الإشعارات'),
                _buildListTile(LucideIcons.globe, 'تغيير اللغة', trailingText: 'العربية'),
                _buildListTile(
                  LucideIcons.moon,
                  'الوضع الليلي',
                  customTrailing: Switch(
                    value: _isDarkMode,
                    activeThumbColor: const Color(0xFF0A7A48),
                    onChanged: (val) {
                      setState(() {
                        _isDarkMode = val;
                      });
                    },
                  ),
                ),
                _buildListTile(
                  LucideIcons.shieldCheck,
                  'الخصوصية والأمان',
                  isLast: true,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityScreen()));
                  },
                ),
              ]),
              const SizedBox(height: 25),

              // 6. زر تسجيل الخروج
              _buildCardSection([
                _buildListTile(
                  LucideIcons.logOut,
                  'تسجيل الخروج',
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  showChevron: false,
                  isLast: true,
                ),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // تصميم بطاقة المستخدم العلوية
  // ==========================================
  Widget _buildUserHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children:[
          // الصورة الرمزية
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A7A48).withOpacity(0.1),
            ),
            child: const Center(
              child: Text(
                'م',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // البيانات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                Text(
                  _fullName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  _email,
                  style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          // زر التعديل
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
            },
            icon: const Icon(LucideIcons.edit3, color: Colors.black87),
          )
        ],
      ),
    );
  }

  // ==========================================
  // تصميم بطاقة العضوية (البطاقة الصحية)
  // ==========================================
  Widget _buildHealthMembershipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children:[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Text(
                  'الملف الطبي الموحد',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  'احصل على استشارات وتوصيل مجاني.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'اعرف المزيد',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 10),
          // أيقونة تعبيرية بدلاً من صورة الهدايا
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF0A7A48).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shieldCheck, size: 40, color: Color(0xFF0A7A48)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // عناوين الأقسام
  // ==========================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
      ),
    );
  }

  // ==========================================
  // الحاوية البيضاء التي تجمع القوائم
  // ==========================================
  Widget _buildCardSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ==========================================
  // تصميم السطر الواحد داخل القائمة
  // ==========================================
  Widget _buildListTile(
      IconData icon,
      String title, {
        String? trailingText,
        Widget? customTrailing,
        bool showChevron = true,
        bool isLast = false,
        Color? textColor,
        Color? iconColor,
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap ?? () {}, // الأزرار لا تعمل فعلياً كما طلبت
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
        ),
        child: Row(
          children:[
            Icon(icon, size: 22, color: iconColor ?? Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? Colors.black87,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                textDirection: TextDirection.ltr,
              ),
              const SizedBox(width: 10),
            ],
            if (customTrailing != null) ...[
              customTrailing,
            ] else if (showChevron) ...[
              const Icon(LucideIcons.chevronLeft, size: 18, color: Colors.grey),
            ],
          ],
        ),
      ),
    );
  }
}