import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'home_screen.dart';
import 'my_orders_screen.dart';
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
  final CartService _cartService = CartService();

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(isGuest: widget.isGuest, userName: widget.userName);
      case 1:
        return MyOrdersScreen(
          key: UniqueKey(),
          isFromBottomNav: true,
        );
      case 2:
        return CartScreen(key: UniqueKey());
      case 3:
        return const ProfileScreen();
      default:
        return Container();
    }
  }

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _getSelectedScreen(_currentIndex),
        bottomNavigationBar: AnimatedBuilder(
          animation: _cartService,
          builder: (context, child) {
            return Container(
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  selectedItemColor: const Color(0xFF0A7A48),
                  unselectedItemColor: Colors.grey,
                  type: BottomNavigationBarType.fixed,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.home),
                      label: 'الرئيسية',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(LucideIcons.shoppingBag),
                      label: 'طلباتي',
                    ),
                    BottomNavigationBarItem(
                      // 💡 النقطة الحمراء: تظهر إذا كانت السلة غير فارغة + المستخدم ليس في صفحة السلة حالياً
                      icon: Badge(
                        isLabelVisible: _currentIndex != 2 && _cartService.items.isNotEmpty,
                        smallSize: 10,
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
            );
          },
        ),
      ),
    );
  }
}