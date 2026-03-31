import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// استدعاء الشاشات الموجودة في نفس المجلد (screens)
import 'home_screen.dart';
import 'my_orders_screen.dart'; // 💡 تم استدعاء شاشة الطلبات
import 'cart_screen.dart';
import 'profile_screen.dart';
import '../services/cart_service.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  final String? userName;
  const MainScreen({super.key, required this.isGuest, this.userName});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(isGuest: widget.isGuest, userName: widget.userName),
      // 💡 شاشة الطلبات أصبحت رقم 1، مع تمرير متغير يخبرها أنها ضمن الشريط السفلي
      const MyOrdersScreen(isFromBottomNav: true),
      // 💡 شاشة السلة أصبحت الآن رقم 2
      CartScreen(key: UniqueKey()),
      // 💡 شاشة الملف الشخصي أصبحت رقم 3
      const ProfileScreen(),
    ];
  }

  // 💡 الحل الذكي لمشكلة الشاشة السوداء (منع الخروج الخاطئ من التطبيق)
  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      // إذا ضغط رجوع وهو في أي صفحة غير الرئيسية، أعده للرئيسية بدل الخروج
      setState(() {
        _currentIndex = 0;
      });
      return false; // نمنع الخروج من التطبيق
    }
    return true; // إذا كان في الرئيسية وضغط رجوع، نسمح بالخروج
  }

  @override
  Widget build(BuildContext context) {
    final int cartCount = CartService().itemCount;

    return WillPopScope(
      // 💡 تغليف الشاشة بـ WillPopScope للتحكم بزر الرجوع
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) {
                setState(() {
                  _currentIndex = i;
                  // 💡 السلة الآن الـ Index تبعها هو 2
                  if (i == 2) {
                    _screens[2] = CartScreen(key: UniqueKey());
                  }
                });
              },
              selectedItemColor: const Color(0xFF0A7A48),
              unselectedItemColor: Colors.grey,
              type: BottomNavigationBarType
                  .fixed, // مهم جداً عندما يكون هناك 4 أزرار
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.home),
                  label: 'الرئيسية',
                ),
                // 💡 الزر الجديد: طلباتي
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.shoppingBag),
                  label: 'طلباتي',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text(
                      '$cartCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    child: const Icon(LucideIcons.shoppingCart),
                  ),
                  label: 'السلة',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(LucideIcons.userCircle),
                  label: 'حسابي',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
