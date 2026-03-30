// ==========================================
// خدمة سلة المشتريات (Cart Service - Singleton)
// ==========================================
// هذا الملف يدير حالة السلة في الذاكرة (In-Memory).
// القيد الأساسي: السلة مقيّدة بصيدلية واحدة فقط في كل طلب.
// ==========================================

class CartItem {
  final int stockId;        // رقم المخزون من PharmacyStock
  final int systemMedId;    // رقم الدواء من SystemMedicine
  final String medicineName;
  final String image;
  final double price;
  final int pharmacistId;
  final String pharmacyName;
  final bool isControlled;  // هل الدواء مراقب (Rx)؟
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

class CartService {
  // ==========================================
  // نمط Singleton (نسخة وحيدة في كل التطبيق)
  // ==========================================
  CartService._internal();
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  // ==========================================
  // البيانات الأساسية
  // ==========================================
  final List<CartItem> _items = [];
  int? _currentPharmacistId;
  String? _currentPharmacyName;

  // ==========================================
  // Getters (للقراءة فقط)
  // ==========================================
  List<CartItem> get items => List.unmodifiable(_items);
  int? get currentPharmacistId => _currentPharmacistId;
  String? get currentPharmacyName => _currentPharmacyName;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  // هل يوجد دواء مراقب في السلة؟ (لإجبار المريض على رفع وصفة)
  bool get hasControlledMedicine => _items.any((item) => item.isControlled);

  // ==========================================
  // إضافة دواء للسلة
  // ==========================================
  // يعيد: 'added' إذا نجح، 'updated' إذا زاد الكمية، 'pharmacy_conflict' إذا صيدلية مختلفة
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
    // التحقق من قيد الصيدلية الواحدة
    if (_currentPharmacistId != null && _currentPharmacistId != pharmacistId) {
      return 'pharmacy_conflict';
    }

    // تعيين الصيدلية الحالية
    _currentPharmacistId = pharmacistId;
    _currentPharmacyName = pharmacyName;

    // البحث عن الدواء في السلة (بناءً على StockID)
    final existingIndex = _items.indexWhere((item) => item.stockId == stockId);

    if (existingIndex != -1) {
      // الدواء موجود مسبقاً: زيادة الكمية
      _items[existingIndex].quantity++;
      return 'updated';
    } else {
      // دواء جديد: إضافته للسلة
      _items.add(CartItem(
        stockId: stockId,
        systemMedId: systemMedId,
        medicineName: medicineName,
        image: image,
        price: price,
        pharmacistId: pharmacistId,
        pharmacyName: pharmacyName,
        isControlled: isControlled,
      ));
      return 'added';
    }
  }

  // ==========================================
  // تعديل الكمية
  // ==========================================
  void updateQuantity(int stockId, int newQuantity) {
    final index = _items.indexWhere((item) => item.stockId == stockId);
    if (index != -1) {
      if (newQuantity <= 0) {
        removeItem(stockId);
      } else {
        _items[index].quantity = newQuantity;
      }
    }
  }

  // ==========================================
  // حذف دواء من السلة
  // ==========================================
  void removeItem(int stockId) {
    _items.removeWhere((item) => item.stockId == stockId);

    // إذا أصبحت السلة فارغة، نزيل قيد الصيدلية
    if (_items.isEmpty) {
      _currentPharmacistId = null;
      _currentPharmacyName = null;
    }
  }

  // ==========================================
  // تفريغ السلة بالكامل
  // ==========================================
  void clearCart() {
    _items.clear();
    _currentPharmacistId = null;
    _currentPharmacyName = null;
  }

  // ==========================================
  // تفريغ السلة والتبديل لصيدلية جديدة
  // ==========================================
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
    clearCart();
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
