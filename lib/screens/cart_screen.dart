import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cart_service.dart';
import '../config/api_config.dart';
import 'map_picker_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cart = CartService();
  final Color primaryColor = const Color(0xFF0A7A48);
  bool _isSubmitting = false;

  // بيانات التوصيل
  double? _deliveryLat;
  double? _deliveryLng;
  String _deliveryAddressText = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'سلة المشتريات',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20),
          ),
          actions: [
            if (_cart.items.isNotEmpty)
              IconButton(
                onPressed: _showClearCartDialog,
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22),
              ),
          ],
        ),
        body: _cart.isEmpty ? _buildEmptyCart() : _buildCartContent(),
        bottomNavigationBar: _cart.isEmpty ? null : _buildBottomBar(),
      ),
    );
  }

  // ==========================================
  // حالة السلة الفارغة
  // ==========================================
  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.shoppingCart, size: 70, color: primaryColor.withOpacity(0.4)),
            ),
            const SizedBox(height: 30),
            const Text(
              'سلتك فارغة',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              'ابحث عن الأدوية وأضفها لسلتك\nلتبدأ عملية الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.6, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // محتوى السلة
  // ==========================================
  Widget _buildCartContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // اسم الصيدلية
          _buildPharmacyHeader(),
          const SizedBox(height: 20),

          // قائمة الأدوية
          ..._cart.items.map((item) => _buildCartItemCard(item)),

          const SizedBox(height: 20),

          // تنبيه الأدوية المراقبة
          if (_cart.hasControlledMedicine)
            _buildControlledWarning(),

          const SizedBox(height: 15),

          // ملخص الأسعار
          _buildPriceSummary(),

          const SizedBox(height: 15),

          // عنوان التوصيل
          _buildDeliverySection(),

          const SizedBox(height: 100), // مسافة للـ bottom bar
        ],
      ),
    );
  }

  // ==========================================
  // هيدر الصيدلية
  // ==========================================
  Widget _buildPharmacyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_pharmacy, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الطلب من:', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  _cart.currentPharmacyName ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_cart.itemCount} أدوية',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // كارد عنصر في السلة
  // ==========================================
  Widget _buildCartItemCard(CartItem item) {
    final String imageUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item.image}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // صورة الدواء
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.pill, color: Colors.grey, size: 30),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // بيانات الدواء
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.medicineName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // زر الحذف
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _cart.removeItem(item.stockId);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(LucideIcons.x, color: Colors.redAccent, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // شارة "مراقب" إذا كان الدواء مراقب
                if (item.isControlled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Rx مراقب', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // السعر
                    Text(
                      '${item.totalPrice.toStringAsFixed(2)} ₪',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryColor),
                      textDirection: TextDirection.ltr,
                    ),

                    // أزرار الكمية
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _buildQuantityButton(
                            icon: LucideIcons.minus,
                            onTap: () {
                              setState(() {
                                _cart.updateQuantity(item.stockId, item.quantity - 1);
                              });
                            },
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 35),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                          _buildQuantityButton(
                            icon: LucideIcons.plus,
                            onTap: () {
                              setState(() {
                                _cart.updateQuantity(item.stockId, item.quantity + 1);
                              });
                            },
                          ),
                        ],
                      ),
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

  Widget _buildQuantityButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  // ==========================================
  // تنبيه الأدوية المراقبة (Rx)
  // ==========================================
  Widget _buildControlledWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.alertTriangle, color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'وصفة طبية مطلوبة!',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.orange.shade800),
                ),
                const SizedBox(height: 4),
                Text(
                  'سلتك تحتوي على أدوية مراقبة (Rx). ستحتاج لتصوير الوصفة الطبية قبل إتمام الطلب.',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ملخص الأسعار
  // ==========================================
  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الطلب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 15),

          _buildPriceRow('إجمالي المنتجات (${_cart.itemCount})', '${_cart.totalAmount.toStringAsFixed(2)} ₪'),
          const SizedBox(height: 8),
          _buildPriceRow('رسوم التوصيل', 'يحدد لاحقاً', isGrey: true),
          const SizedBox(height: 8),
          _buildPriceRow('طريقة الدفع', 'الدفع عند الاستلام (COD)', isGrey: true),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Color(0xFFF0F0F0)),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('المجموع الكلي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.black87)),
              Text(
                '${_cart.totalAmount.toStringAsFixed(2)} ₪',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryColor),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGrey = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isGrey ? Colors.grey : Colors.black87,
          ),
          textDirection: TextDirection.ltr,
        ),
      ],
    );
  }

  // ==========================================
  // قسم عنوان التوصيل
  // ==========================================
  Widget _buildDeliverySection() {
    bool hasAddress = _deliveryLat != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAddress ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasAddress ? Colors.green.shade200 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasAddress ? LucideIcons.checkCircle2 : LucideIcons.mapPin,
                color: hasAddress ? Colors.green : primaryColor,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text('عنوان التوصيل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),

          if (hasAddress)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'تم تحديد الموقع: (${_deliveryLat!.toStringAsFixed(4)}, ${_deliveryLng!.toStringAsFixed(4)})',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickDeliveryLocation,
              icon: Icon(hasAddress ? LucideIcons.edit3 : LucideIcons.navigation, size: 18),
              label: Text(hasAddress ? 'تغيير الموقع' : 'تحديد موقع التوصيل', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
                side: BorderSide(color: primaryColor.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // الشريط السفلي (زر إتمام الطلب)
  // ==========================================
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, -5))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              elevation: 4,
              shadowColor: primaryColor.withOpacity(0.4),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 25, width: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.shoppingBag, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text('إتمام الطلب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_cart.totalAmount.toStringAsFixed(2)} ₪',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // الدوال الوظيفية
  // ==========================================

  // فتح خريطة تحديد عنوان التوصيل
  Future<void> _pickDeliveryLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapPickerScreen()),
    );

    if (result != null) {
      setState(() {
        _deliveryLat = result.latitude;
        _deliveryLng = result.longitude;
      });
    }
  }

  // حوار تأكيد تفريغ السلة
  void _showClearCartDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'تفريغ السلة؟',
      desc: 'هل أنت متأكد من حذف جميع الأدوية من السلة؟',
      btnCancelOnPress: () {},
      btnCancelText: 'إلغاء',
      btnOkOnPress: () {
        setState(() {
          _cart.clearCart();
        });
      },
      btnOkText: 'تفريغ',
      btnOkColor: Colors.redAccent,
    ).show();
  }

  // إرسال الطلب للسيرفر
  Future<void> _submitOrder() async {
    // التحقق من تسجيل الدخول
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isGuest = prefs.getBool('isGuest') ?? false;
    String? userId = prefs.getString('userId');

    if (isGuest || userId == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        title: 'تسجيل الدخول مطلوب',
        desc: 'يجب عليك تسجيل الدخول أولاً لإتمام عملية الطلب.',
        btnOkOnPress: () {},
        btnOkColor: primaryColor,
        btnOkText: 'حسناً',
      ).show();
      return;
    }

    // التحقق من تحديد عنوان التوصيل
    if (_deliveryLat == null || _deliveryLng == null) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.warning,
        title: 'العنوان مطلوب',
        desc: 'الرجاء تحديد موقع التوصيل على الخريطة قبل إتمام الطلب.',
        btnOkOnPress: () {},
        btnOkColor: Colors.orange,
        btnOkText: 'حسناً',
      ).show();
      return;
    }

    setState(() { _isSubmitting = true; });

    try {
      // تجهيز بيانات عناصر الطلب
      List<Map<String, dynamic>> orderItems = _cart.items.map((item) => {
        'stock_id': item.stockId,
        'quantity': item.quantity,
        'sold_price': item.price,
      }).toList();

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}create_order.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": int.parse(userId),
          "total_amount": _cart.totalAmount,
          "delivery_address": _deliveryAddressText.isNotEmpty ? _deliveryAddressText : "موقع مُحدد على الخريطة",
          "delivery_lat": _deliveryLat,
          "delivery_lng": _deliveryLng,
          "items": orderItems,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // نجاح - تفريغ السلة وإظهار رسالة
          _cart.clearCart();

          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم إرسال الطلب!',
            desc: 'طلبك رقم #${data['order_id']} قيد المراجعة الآن. سيقوم الصيدلي بمراجعته والرد عليك.',
            btnOkOnPress: () {
              setState(() {}); // تحديث الشاشة لإظهار السلة فارغة
            },
            btnOkColor: primaryColor,
            btnOkText: 'ممتاز!',
          ).show();
        } else {
          _showErrorDialog(data['message'] ?? 'حدث خطأ غير متوقع');
        }
      } else {
        _showErrorDialog('فشل الاتصال بالسيرفر (${response.statusCode})');
      }
    } catch (e) {
      _showErrorDialog('خطأ في الاتصال: $e');
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: 'خطأ',
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      btnOkText: 'حسناً',
    ).show();
  }
}
