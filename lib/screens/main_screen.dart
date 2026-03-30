import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// استدعاء الشاشات الموجودة في نفس المجلد (screens)
import 'home_screen.dart';
import 'search_screen.dart';
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
      const SearchScreen(),
      // شاشة السلة — ستُعاد بنائها كل مرة يتم فتحها (بـ UniqueKey)
      CartScreen(key: UniqueKey()),
      // شاشة الملف الشخصي التي قمنا بتصميمها
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final int cartCount = CartService().itemCount;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10)
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() {
                _currentIndex = i;
                // 💡 كل مرة يضغط على تبويب السلة، نعيد بناءها لتقرأ البيانات المحدثة
                if (i == 2) {
                  _screens[2] = CartScreen(key: UniqueKey());
                }
              });
            },
            selectedItemColor: const Color(0xFF0A7A48),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: [
              const BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
              const BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'البحث'),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: cartCount > 0,
                  label: Text('$cartCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.redAccent,
                  child: const Icon(LucideIcons.shoppingCart),
                ),
                label: 'السلة',
              ),
              const BottomNavigationBarItem(icon: Icon(LucideIcons.userCircle), label: 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }
}