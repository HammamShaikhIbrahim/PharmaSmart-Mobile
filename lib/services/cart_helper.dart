import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import '../services/cart_service.dart';

// ==========================================
// دوال مساعدة للتعامل مع السلة من أي شاشة
// ==========================================

class CartHelper {
  static final CartService _cart = CartService();

  /// إضافة دواء للسلة مع معالجة تعارض الصيدليات
  static void addToCart({
    required BuildContext context,
    required int stockId,
    required int systemMedId,
    required String medicineName,
    required String image,
    required double price,
    required int pharmacistId,
    required String pharmacyName,
    required bool isControlled,
    VoidCallback? onSuccess,
  }) {
    final result = _cart.addItem(
      stockId: stockId,
      systemMedId: systemMedId,
      medicineName: medicineName,
      image: image,
      price: price,
      pharmacistId: pharmacistId,
      pharmacyName: pharmacyName,
      isControlled: isControlled,
    );

    const Color primaryColor = Color(0xFF0A7A48);

    switch (result) {
      case 'added':
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('تمت إضافة "$medicineName" للسلة', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(15),
            duration: const Duration(seconds: 2),
          ),
        );
        onSuccess?.call();
        break;

      case 'updated':
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.add_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('تم زيادة كمية "$medicineName"', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(15),
            duration: const Duration(seconds: 2),
          ),
        );
        onSuccess?.call();
        break;

      case 'pharmacy_conflict':
        // إظهار حوار تنبيه بأن السلة تحتوي على أدوية من صيدلية أخرى
        AwesomeDialog(
          context: context,
          dialogType: DialogType.warning,
          title: 'تبديل الصيدلية؟',
          desc: 'سلتك تحتوي على أدوية من "${_cart.currentPharmacyName}".\n\nهل تريد تفريغ السلة والبدء من "$pharmacyName"؟',
          btnCancelOnPress: () {},
          btnCancelText: 'إبقاء السلة',
          btnOkOnPress: () {
            _cart.clearAndAddNew(
              stockId: stockId,
              systemMedId: systemMedId,
              medicineName: medicineName,
              image: image,
              price: price,
              pharmacistId: pharmacistId,
              pharmacyName: pharmacyName,
              isControlled: isControlled,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تفريغ السلة وإضافة "$medicineName" من "$pharmacyName"', style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(15),
              ),
            );
            onSuccess?.call();
          },
          btnOkText: 'تفريغ وتبديل',
          btnOkColor: Colors.orange,
        ).show();
        break;
    }
  }
}
