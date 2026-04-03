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
import 'main_screen.dart'; 
import '../widgets/pharma_ui.dart'; 

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

  final TextEditingController _addressDescController = TextEditingController();

  int _selectedAddressOption = 0; 
  List<Map<String, dynamic>> _customAddresses = [];

  double? _deliveryLat;
  double? _deliveryLng;

  Uint8List? _prescriptionImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCustomAddresses();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cart.markCartAsViewed();
    });
  }

  Future<void> _loadCustomAddresses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    if (userId != null) {
      List<String> savedList = prefs.getStringList('custom_addresses_$userId') ?? [];
      setState(() {
        _customAddresses = savedList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  void dispose() {
    _addressDescController.dispose();
    super.dispose();
  }

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
          // 💡 العداد غير موجود هنا بناءً على طلبك
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
    return PharmaUI.emptyState(
      icon: LucideIcons.shoppingCart,
      title: 'سلتك فارغة',
      subtitle:
          'تصفح الصيدليات وأضف الأدوية التي تحتاجها إلى سلتك لتبدأ عملية الطلب.',
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

  // 💡 تصميم كرت الصيدلية الجديد المفصل والأنيق
  Widget _buildPharmacyHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. الجزء العلوي: اسم الصيدلية
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  FontAwesomeIcons.houseMedical,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'يتم تجهيز طلبك من:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _cart.currentPharmacyName ?? 'صيدلية غير محددة',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Color(0xFFF0F0F0), height: 1),
          ),

          // 2. الجزء السفلي: الإحصائيات (الأصناف والقطع)
          Row(
            children: [
              // مربع الأصناف المختلفة
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_cart.uniqueItemsCount}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'أصناف مختلفة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // مربع إجمالي القطع
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_cart.totalItemsQuantity}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'إجمالي القطع',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildRxUploadSection() {
    bool isMandatory = _cart.hasControlledMedicine;

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
        : 'إذا كان لديك وصفة طبية وتريد إرفاقها للصيدلي، يمكنك رفع صورتها هنا.';

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

          _buildAddressOptionRadio(
            title: 'العنوان الأساسي',
            subtitle: 'المسجل في الملف الشخصي',
            value: 0,
            icon: LucideIcons.home,
          ),

          ..._customAddresses.asMap().entries.map((entry) {
            return _buildAddressOptionRadio(
              title: entry.value['title'],
              subtitle: entry.value['desc'],
              value: entry.key + 1,
              icon: LucideIcons.mapPin,
            );
          }),

          _buildAddressOptionRadio(
            title: 'تحديد موقع جديد (GPS)',
            value: -1,
            icon: LucideIcons.navigation,
          ),

          if (_selectedAddressOption == -1) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _addressDescController,
              decoration: InputDecoration(
                hintText: 'وصف العنوان (المنطقة، الشارع، المعلم، ...)',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(
                  LucideIcons.penTool,
                  color: Colors.grey,
                  size: 18,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (hasMapAddress)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'تم التحديد: (${_deliveryLat!.toStringAsFixed(4)}, ${_deliveryLng!.toStringAsFixed(4)})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
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
                  hasMapAddress ? LucideIcons.checkCircle2 : LucideIcons.map,
                  size: 18,
                  color: hasMapAddress ? Colors.green : primaryColor,
                ),
                label: Text(
                  hasMapAddress ? 'تم تحديد الموقع' : 'افتح الخريطة لتحديد الموقع',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: hasMapAddress ? Colors.green : primaryColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: hasMapAddress ? Colors.green : primaryColor.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddressOptionRadio({
    required String title,
    String? subtitle,
    required int value,
    required IconData icon,
  }) {
    bool isSelected = _selectedAddressOption == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAddressOption = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13, 
                      color: Colors.black87
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11, 
                        color: Colors.grey, 
                        fontWeight: FontWeight.bold
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
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
              // 💡 تم تعديل الكلمة هنا لتعكس عدد القطع بدقة
              Text(
                'المجموع الفرعي (${_cart.totalItemsQuantity} قطع)',
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
          _addressDescController.clear();
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

    String finalAddressDesc = "";
    bool useSavedLoc = false;
    double? finalLat;
    double? finalLng;

    if (_selectedAddressOption == 0) {
      useSavedLoc = true;
      finalAddressDesc = "العنوان الأساسي (من الملف الشخصي)";
    } else if (_selectedAddressOption == -1) {
      useSavedLoc = false;
      if (_addressDescController.text.trim().isEmpty) {
        _showAwesomeError(
          'وصف العنوان مطلوب',
          'الرجاء كتابة وصف للعنوان في المربع المخصص.',
        );
        return;
      }
      if (_deliveryLat == null || _deliveryLng == null) {
        _showAwesomeError(
          'موقع الخريطة مطلوب',
          'الرجاء تحديد الموقع الجغرافي على الخريطة.',
        );
        return;
      }
      finalAddressDesc = _addressDescController.text.trim();
      finalLat = _deliveryLat;
      finalLng = _deliveryLng;
    } else {
      useSavedLoc = false;
      int listIndex = _selectedAddressOption - 1;
      finalAddressDesc = _customAddresses[listIndex]['desc'];
      finalLat = _customAddresses[listIndex]['lat'];
      finalLng = _customAddresses[listIndex]['lng'];
    }

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
          "delivery_address": finalAddressDesc,
          "use_saved_location": useSavedLoc,
          "delivery_lat": finalLat,
          "delivery_lng": finalLng,
          "items": orderItems,
          "prescription_image": base64Image,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _cart.clearCart();
          _prescriptionImageBytes = null;
          _addressDescController.clear();

          if (!mounted) return;

          AwesomeDialog(
            context: context,
            dialogType: DialogType.success,
            title: 'تم إرسال الطلب!',
            desc: 'طلبك رقم #${data['order_id']} قيد المراجعة الآن.',
            btnOkColor: primaryColor,
            btnOkText: 'العودة للرئيسية',
            dismissOnTouchOutside: false,
            btnOkOnPress: () async {
              final prefs = await SharedPreferences.getInstance();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => MainScreen(
                    isGuest: false,
                    userName: prefs.getString('userName'),
                  ),
                ),
                (route) => false,
              );
            },
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