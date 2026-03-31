import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

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
  bool _isSubmitting = false;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  int _addressType = 1;
  double? _deliveryLat;
  double? _deliveryLng;

  Uint8List? _prescriptionImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _prescriptionImageBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'إرفاق الوصفة الطبية',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(LucideIcons.camera, 'الكاميرا', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  }),
                  _buildSourceButton(LucideIcons.image, 'المعرض', () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
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
          centerTitle: true,
          title: const Text(
            "سلة المشتريات",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          actions: [
            if (_cart.items.isNotEmpty)
              IconButton(
                onPressed: _showClearCartDialog,
                icon: const Icon(
                  LucideIcons.trash2,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
          ],
        ),
        body: _cart.isEmpty ? _buildEmptyCart() : _buildCartContent(),
        bottomNavigationBar: _cart.isEmpty ? null : _buildBottomBar(),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.cartArrowDown,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 20),
            const Text(
              'سلتك فارغة',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'تصفح الصيدليات وأضف الأدوية التي تحتاجها إلى سلتك لتبدأ عملية الطلب.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPharmacyHeader(),
          const SizedBox(height: 20),

          ..._cart.items.map((item) => _buildCartItemCard(item)),
          const SizedBox(height: 10),

          // 💡 منطقة الرفع أصبحت تظهر دائماً (ستتغير ألوانها برمجياً حسب نوع الأدوية)
          _buildRxUploadSection(),
          const SizedBox(height: 20),

          _buildDeliverySection(),
          const SizedBox(height: 20),

          _buildPriceSummary(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPharmacyHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              FontAwesomeIcons.houseMedical,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الطلب من صيدلية:',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _cart.currentPharmacyName ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final String imageUrl =
        "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item.image}";

    return Dismissible(
      key: Key(item.stockId.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) {
        setState(() {
          _cart.removeItem(item.stockId);
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isControlled)
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Rx",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.price} ₪',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildQtyBtn(
                          LucideIcons.plus,
                          () => setState(
                            () => _cart.updateQuantity(
                              item.stockId,
                              item.quantity + 1,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 35),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        _buildQtyBtn(
                          LucideIcons.minus,
                          () => setState(
                            () => _cart.updateQuantity(
                              item.stockId,
                              item.quantity - 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Center(
                    child: FaIcon(
                      FontAwesomeIcons.pills,
                      color: Colors.grey.shade300,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  // ==========================================
  // 💡 4. منطقة الرفع (الديناميكية) للوصفة
  // ==========================================
  Widget _buildRxUploadSection() {
    // تحديد الحالة: هل يوجد دواء مراقب أم لا؟
    bool isMandatory = _cart.hasControlledMedicine;

    // الألوان والنصوص بناءً على الحالة
    Color boxColor = isMandatory ? Colors.red.shade50 : Colors.blue.shade50;
    Color borderColor = isMandatory
        ? Colors.red.shade200
        : Colors.blue.shade200;
    Color iconColor = isMandatory ? Colors.red.shade700 : Colors.blue.shade600;
    Color textColor = isMandatory ? Colors.red.shade800 : Colors.blue.shade800;
    Color dashedBorderColor = isMandatory
        ? Colors.red.shade300
        : Colors.blue.shade300;

    FaIconData titleIcon = isMandatory
        ? FontAwesomeIcons.triangleExclamation
        : FontAwesomeIcons.filePrescription;
    String titleText = isMandatory
        ? 'وصفة طبية مطلوبة (إجباري)'
        : 'إرفاق وصفة طبية (اختياري)';
    String descText = isMandatory
        ? 'سلتك تحتوي على أدوية مراقبة، يرجى إرفاق صورة واضحة للوصفة الطبية لإتمام الطلب.'
        : 'إذا كان لديك وصفة طبية (روشتة) وتريد إرفاقها للصيدلي، يمكنك رفع صورتها هنا.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(titleIcon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                titleText,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descText,
            style: TextStyle(
              fontSize: 12,
              color: iconColor.withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),

          GestureDetector(
            onTap: _showImageSourceDialog,
            child: _prescriptionImageBytes == null
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: dashedBorderColor,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.camera,
                          color: iconColor.withOpacity(0.7),
                          size: 30,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط هنا لرفع الوصفة',
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _prescriptionImageBytes!,
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: InkWell(
                          onTap: () =>
                              setState(() => _prescriptionImageBytes = null),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySection() {
    bool hasMapAddress = _deliveryLat != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
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
              Icon(LucideIcons.mapPin, color: primaryColor, size: 20),
              const SizedBox(width: 10),
              const Text(
                'إلى أين نرسل الطلب؟',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          GestureDetector(
            onTap: () => setState(() => _addressType = 1),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _addressType == 1
                    ? primaryColor.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _addressType == 1
                      ? primaryColor
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _addressType == 1
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _addressType == 1 ? primaryColor : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "عنواني المسجل في الحساب",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () => setState(() => _addressType = 2),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _addressType == 2
                    ? primaryColor.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _addressType == 2
                      ? primaryColor
                      : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _addressType == 2
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _addressType == 2 ? primaryColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "تحديد موقع جديد على الخريطة",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_addressType == 2) ...[
                    const SizedBox(height: 12),
                    if (hasMapAddress)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'تم التحديد: (${_deliveryLat!.toStringAsFixed(4)}, ${_deliveryLng!.toStringAsFixed(4)})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MapPickerScreen(),
                            ),
                          );
                          if (result != null && result is LatLng) {
                            setState(() {
                              _deliveryLat = result.latitude;
                              _deliveryLng = result.longitude;
                            });
                          }
                        },
                        icon: Icon(
                          hasMapAddress
                              ? LucideIcons.edit3
                              : LucideIcons.navigation,
                          size: 16,
                        ),
                        label: Text(
                          hasMapAddress ? 'تغيير الموقع' : 'افتح الخريطة',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: BorderSide(
                            color: primaryColor.withOpacity(0.5),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'فاتورة الطلب',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المجموع الفرعي (${_cart.itemCount})',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_cart.totalAmount.toStringAsFixed(2)} ₪',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'طريقة الدفع',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'الدفع عند الاستلام (COD)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'المجموع الكلي',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_cart.totalAmount.toStringAsFixed(2)} ₪',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.4),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'تأكيد الطلب',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            LucideIcons.arrowLeft,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      title: 'تفريغ السلة؟',
      desc: 'هل أنت متأكد من حذف جميع الأدوية؟',
      btnCancelOnPress: () {},
      btnCancelText: 'إلغاء',
      btnOkOnPress: () {
        setState(() {
          _cart.clearCart();
          _prescriptionImageBytes = null;
        });
      },
      btnOkText: 'تفريغ',
      btnOkColor: Colors.redAccent,
    ).show();
  }

  Future<void> _submitOrder() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isGuest = prefs.getBool('isGuest') ?? false;
    String? userId = prefs.getString('userId');

    if (isGuest || userId == null) {
      _showAwesomeInfo(
        'تسجيل الدخول مطلوب',
        'يجب عليك تسجيل الدخول أولاً لإتمام عملية الطلب.',
      );
      return;
    }

    if (_addressType == 2 && (_deliveryLat == null || _deliveryLng == null)) {
      _showAwesomeError(
        'موقع الخريطة مطلوب',
        'لقد اخترت توصيل لموقع جديد، الرجاء تحديده على الخريطة.',
      );
      return;
    }

    // 💡 التحقق الذكي من الروشتة الإجبارية
    if (_cart.hasControlledMedicine && _prescriptionImageBytes == null) {
      _showAwesomeError(
        'الوصفة الطبية مطلوبة',
        'سلتك تحتوي على أدوية مراقبة، يجب إرفاق صورة الوصفة الطبية.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      List<Map<String, dynamic>> orderItems = _cart.items
          .map(
            (item) => {
              'stock_id': item.stockId,
              'quantity': item.quantity,
              'sold_price': item.price,
            },
          )
          .toList();

      String? base64Image;
      if (_prescriptionImageBytes != null) {
        base64Image = base64Encode(_prescriptionImageBytes!);
      }

      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}create_order.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": int.parse(userId),
          "total_amount": _cart.totalAmount,
          "delivery_address": _addressType == 1
              ? "العنوان المسجل في الحساب"
              : "موقع مُحدد على الخريطة",
          "delivery_lat": _addressType == 2 ? _deliveryLat : null,
          "delivery_lng": _addressType == 2 ? _deliveryLng : null,
          "items": orderItems,
          "prescription_image": base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _cart.clearCart();
          _prescriptionImageBytes = null;

          if (!mounted) return;
          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم إرسال الطلب!',
            desc: 'طلبك رقم #${data['order_id']} قيد المراجعة الآن.',
            btnOkOnPress: () => setState(() {}),
            btnOkColor: primaryColor,
            btnOkText: 'ممتاز!',
          ).show();
        } else {
          _showAwesomeError('خطأ', data['message'] ?? 'حدث خطأ غير متوقع');
        }
      } else {
        _showAwesomeError('خطأ السيرفر', 'فشل الاتصال بالسيرفر');
      }
    } catch (e) {
      _showAwesomeError('خطأ في الاتصال', 'تأكد من تشغيل الإنترنت والسيرفر');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAwesomeError(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkColor: Colors.redAccent,
      btnOkText: 'حسناً',
    ).show();
  }

  void _showAwesomeInfo(String title, String desc) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.info,
      title: title,
      desc: desc,
      btnOkOnPress: () {},
      btnOkColor: primaryColor,
      btnOkText: 'حسناً',
    ).show();
  }
}
