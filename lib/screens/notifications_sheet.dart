import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class NotificationsSheet extends StatefulWidget {
  const NotificationsSheet({super.key});

  // 💡 دالة لفتح النافذة
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationsSheet(),
    );
  }

  @override
  State<NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<NotificationsSheet> {
  bool _isLoading = true;
  bool _isGuest = false;
  final List<Map<String, dynamic>> _notifications = [];
  String _selectedTab = 'all';

  // ألوان مطابقة للويب تماماً
  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  final List<Map<String, dynamic>> _tabs = [
    {'id': 'all', 'title': 'الكل', 'icon': LucideIcons.layers, 'isSoon': false},
    {
      'id': 'orders',
      'title': 'الطلبات',
      'icon': LucideIcons.shoppingBag,
      'isSoon': false,
    },
    {
      'id': 'reminders',
      'title': 'منبه الأدوية',
      'icon': LucideIcons.clock,
      'isSoon': true,
    },
    {
      'id': 'messages',
      'title': 'الرسائل',
      'icon': LucideIcons.messageCircle,
      'isSoon': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;
    String? userId = prefs.getString('userId');

    if (_isGuest || userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. الإشعارات المستقبلية (بدون إيموجي)
      _notifications.add({
        'id': 'mock1',
        'title': 'ميزة منبه الأدوية الذكي',
        'body':
            'قريباً سيتيح لك التطبيق جدولة أدويتك وسنقوم بتذكيرك بمواعيد تناولها بدقة لضمان التزامك بالعلاج.',
        'time': 'قريباً',
        'type': 'reminders',
        'isSoon': true,
      });

      _notifications.add({
        'id': 'mock2',
        'title': 'المحادثات المباشرة',
        'body':
            'قريباً ستتمكن من المراسلة الفورية والآمنة مع الصيدلي للاستشارة الطبية أو الاستفسار عن بدائل الأدوية.',
        'time': 'قريباً',
        'type': 'messages',
        'isSoon': true,
      });

      // 2. جلب الطلبات الحقيقية (بدون إيموجي)
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}patient_orders.php?patient_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          List orders = data['orders'];

          for (var order in orders) {
            String status = order['Status'];
            if (status == 'Pending') continue;

            String nTitle = '';
            String nBody = '';

            if (status == 'Accepted') {
              nTitle = 'تم قبول طلبك';
              nBody =
                  'صيدلية ${order['PharmacyName']} تقوم بتجهيز طلبك رقم #${order['OrderID']} الآن.';
            } else if (status == 'Delivered') {
              nTitle = 'اكتمل الطلب';
              nBody =
                  'تم تسليم طلبك رقم #${order['OrderID']} بنجاح، نتمنى لك دوام الصحة والعافية.';
            } else if (status == 'Rejected') {
              nTitle = 'تم رفض الطلب';
              nBody =
                  'تم رفض طلبك رقم #${order['OrderID']}. السبب: ${order['RejectionReason'] ?? "غير محدد"}';
            }

            _notifications.add({
              'id': order['OrderID'].toString(),
              'title': nTitle,
              'body': nBody,
              'time': order['OrderDate'].toString().split(' ')[0],
              'type': 'orders',
              'status': status,
              'isSoon': false,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (_selectedTab == 'all') return _notifications;
    return _notifications.where((n) => n['type'] == _selectedTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // مقبض السحب (Drag Handle)
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 15),

            // الهيدر
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "مركز الإشعارات",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.x,
                        color: Colors.grey.shade600,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // شريط التبويبات (Tabs) - مطابق للويب
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: _tabs.length,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final isSelected = _selectedTab == tab['id'];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = tab['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : Colors.grey.shade200,
                          width: 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab['icon'],
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tab['title'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (tab['isSoon']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.amber.shade200,
                                ),
                              ),
                              child: Text(
                                "قريباً",
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.amber.shade700,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w900, // 💡 تم التصحيح هنا
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.black12, height: 1),
            ),

            // محتوى الإشعارات
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : _isGuest
                  ? _buildGuestMessage()
                  : filteredNotifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(
                          filteredNotifications[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 تصميم كرت الإشعار الاحترافي (بدون إيموجي ومطابق لبطاقات الويب)
  Widget _buildNotificationCard(Map<String, dynamic> notif) {
    Color iconBgColor;
    Color iconColor;
    IconData icon;
    Color cardBorderColor = Colors.grey.shade100; // لون الإطار الافتراضي الخفيف

    if (notif['type'] == 'reminders') {
      iconBgColor = Colors.orange.shade50;
      iconColor = Colors.orange.shade600;
      icon = LucideIcons.pill;
    } else if (notif['type'] == 'messages') {
      iconBgColor = Colors.purple.shade50;
      iconColor = Colors.purple.shade600;
      icon = LucideIcons.messageSquare;
    } else if (notif['type'] == 'orders') {
      if (notif['status'] == 'Accepted') {
        iconBgColor = Colors.blue.shade50;
        iconColor = Colors.blue.shade600;
        icon = LucideIcons.packageCheck;
      } else if (notif['status'] == 'Delivered') {
        iconBgColor = Colors.green.shade50;
        iconColor = Colors.green.shade600;
        icon = LucideIcons.checkCheck;
      } else {
        iconBgColor = Colors.red.shade50;
        iconColor = Colors.red.shade600;
        icon = LucideIcons.xCircle;
      }
    } else {
      iconBgColor = primaryColor.withOpacity(0.1);
      iconColor = primaryColor;
      icon = LucideIcons.bellRing;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18), // حواف داخلية ممتازة
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // حواف ناعمة
        border: Border.all(color: cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // ظل خفيف جداً مطابق للويب
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    if (notif['isSoon'])
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          "قريباً",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900, // 💡 تم التصحيح هنا
                            color: Colors.amber.shade700,
                          ),
                        ),
                      )
                    else
                      Text(
                        notif['time'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  notif['body'],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600, // خط مريح للقراءة
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.bellOff,
              size: 50,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد إشعارات في هذا القسم',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.userX,
              size: 50,
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'سجل دخولك لتتمكن من رؤية الإشعارات',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
