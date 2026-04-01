import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../widgets/pharma_ui.dart';

class MyOrdersScreen extends StatefulWidget {
  final bool isFromBottomNav; // 💡 أضفنا هذا المتغير السحري

  const MyOrdersScreen({
    super.key,
    this.isFromBottomNav = false,
  }); // افتراضياً False

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  // ... (أبقِ دالة _fetchOrders كما هي بالضبط)
  Future<void> _fetchOrders() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}patient_orders.php?patient_id=$userId"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _orders = data['orders'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
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
            "سجل طلباتي",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
            ),
          ),
          centerTitle: true,
          // 💡 هنا يتم إخفاء سهم الرجوع إذا كانت الشاشة من ضمن الشريط السفلي
          leading: widget.isFromBottomNav
              ? const SizedBox()
              : IconButton(
                  icon: const Icon(
                    LucideIcons.arrowRight,
                    color: Colors.black87,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
        ),
        body: _isLoading
            ? Center(child: PharmaUI.loader())
            : _orders.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                itemCount: _orders.length,
                itemBuilder: (context, index) =>
                    _buildOrderCard(_orders[index]),
              ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final String status = order['Status'];
    final String pharmacyName = order['PharmacyName'] ?? 'صيدلية';
    final String totalAmount = order['TotalAmount'] ?? '0.00';
    final String orderDate = order['OrderDate'] ?? '';
    final String rejectionReason = order['RejectionReason'] ?? '';
    final List items = order['items'] ?? [];

    // تحديد ألوان وأيقونات الحالة (نفس الألوان في الويب)
    Color statusColor;
    Color statusBgColor;
    String statusText;
    IconData statusIcon;

    if (status == 'Pending') {
      statusColor = Colors.orange.shade700;
      statusBgColor = Colors.orange.shade50;
      statusText = "قيد المراجعة";
      statusIcon = LucideIcons.clock;
    } else if (status == 'Accepted') {
      statusColor = Colors.blue.shade700;
      statusBgColor = Colors.blue.shade50;
      statusText = "جاري التجهيز والتوصيل";
      statusIcon = LucideIcons.packageOpen;
    } else if (status == 'Delivered') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
      statusText = "مكتمل";
      statusIcon = LucideIcons.checkCircle2;
    } else {
      statusColor = Colors.red.shade700;
      statusBgColor = Colors.red.shade50;
      statusText = "مرفوض";
      statusIcon = LucideIcons.xCircle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الهيدر (معلومات الصيدلية والحالة)
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.houseMedical,
                        color: primaryColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pharmacyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          orderDate.split(' ')[0],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // 💡 سبب الرفض إن وُجد
          if (status == 'Rejected' && rejectionReason.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade50.withOpacity(0.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, color: Colors.red.shade400, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "سبب الإلغاء من الصيدلية:",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          rejectionReason,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (status == 'Rejected' && rejectionReason.isNotEmpty)
            const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // قائمة الأدوية
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Icon(
                                LucideIcons.pill,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "${item['Quantity']}x",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            item['MedicineName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${item['SoldPrice']} ₪",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // الفوتر (الإجمالي ورقم الطلب)
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "طلب #ORD-${order['OrderID']}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.ltr,
                ),
                Row(
                  children: [
                    const Text(
                      "الإجمالي: ",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      "$totalAmount ₪",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return PharmaUI.emptyState(
      icon: LucideIcons.packageOpen,
      title: 'لا توجد طلبات سابقة',
      subtitle: 'قم بإضافة أدوية للسلة وإتمام طلبك الأول من الصيدليات المتاحة!',
    );
  }
}
