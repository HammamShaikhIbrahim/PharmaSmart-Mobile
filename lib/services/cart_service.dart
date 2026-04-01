import 'package:flutter/material.dart'; // 💡 أضفنا هاد لاستخدام ChangeNotifier

class CartItem {
  final int stockId;
  final int systemMedId;
  final String medicineName;
  final String image;
  final double price;
  final int pharmacistId;
  final String pharmacyName;
  final bool isControlled;
  int quantity;

  CartItem({
    required this.stockId,
    required this.systemMedId,
    required this.medicineName,
    required this.image,
    required this.price,
    required this.pharmacistId,
    required this.pharmacyName,
    required this.isControlled,
    this.quantity = 1,
  });

  double get totalPrice => price * quantity;
}

// 💡 جعلنا الكلاس ChangeNotifier ليرسل تنبيهات للتطبيق
class CartService extends ChangeNotifier {
  CartService._internal();
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  final List<CartItem> _items = [];
  int? _currentPharmacistId;
  String? _currentPharmacyName;

  List<CartItem> get items => List.unmodifiable(_items);
  int? get currentPharmacistId => _currentPharmacistId;
  String? get currentPharmacyName => _currentPharmacyName;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get hasControlledMedicine => _items.any((item) => item.isControlled);

  String addItem({
    required int stockId,
    required int systemMedId,
    required String medicineName,
    required String image,
    required double price,
    required int pharmacistId,
    required String pharmacyName,
    required bool isControlled,
  }) {
    if (_currentPharmacistId != null && _currentPharmacistId != pharmacistId) {
      return 'pharmacy_conflict';
    }
    _currentPharmacistId = pharmacistId;
    _currentPharmacyName = pharmacyName;
    final existingIndex = _items.indexWhere((item) => item.stockId == stockId);
    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          stockId: stockId,
          systemMedId: systemMedId,
          medicineName: medicineName,
          image: image,
          price: price,
          pharmacistId: pharmacistId,
          pharmacyName: pharmacyName,
          isControlled: isControlled,
        ),
      );
    }
    notifyListeners(); // 💡 تنبيه التطبيق لتحديث العداد فوراً
    return existingIndex != -1 ? 'updated' : 'added';
  }

  void updateQuantity(int stockId, int newQuantity) {
    final index = _items.indexWhere((item) => item.stockId == stockId);
    if (index != -1) {
      if (newQuantity <= 0)
        removeItem(stockId);
      else
        _items[index].quantity = newQuantity;
      notifyListeners(); // 💡 تنبيه التطبيق
    }
  }

  void removeItem(int stockId) {
    _items.removeWhere((item) => item.stockId == stockId);
    if (_items.isEmpty) {
      _currentPharmacistId = null;
      _currentPharmacyName = null;
    }
    notifyListeners(); // 💡 تنبيه التطبيق
  }

  void clearCart() {
    _items.clear();
    _currentPharmacistId = null;
    _currentPharmacyName = null;
    notifyListeners(); // 💡 تنبيه التطبيق
  }

  void clearAndAddNew({
    required int stockId,
    required int systemMedId,
    required String medicineName,
    required String image,
    required double price,
    required int pharmacistId,
    required String pharmacyName,
    required bool isControlled,
  }) {
    _items.clear();
    addItem(
      stockId: stockId,
      systemMedId: systemMedId,
      medicineName: medicineName,
      image: image,
      price: price,
      pharmacistId: pharmacistId,
      pharmacyName: pharmacyName,
      isControlled: isControlled,
    );
  }
}
