import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'home_screen.dart';
import 'search_screen.dart';

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
      const Center(child: Text("سلة المشتريات (قريباً)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48)))),
      const Center(child: Text("الملف الشخصي (قريباً)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A7A48)))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: const Color(0xFF0A7A48),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'الرئيسية'),
              BottomNavigationBarItem(icon: Icon(LucideIcons.search), label: 'البحث'),
              BottomNavigationBarItem(icon: Icon(LucideIcons.shoppingCart), label: 'السلة'), // تم التعديل
              BottomNavigationBarItem(icon: Icon(LucideIcons.userCircle), label: 'حسابي'),
            ],
          ),
        ),
      ),
    );
  }
}