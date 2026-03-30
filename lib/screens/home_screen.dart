import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart'; // مكتبة التنبيهات الجميلة

import '../config/api_config.dart';
import 'pharmacy_list_screen.dart';
import 'search_screen.dart';
import 'pharmacy_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String? userName;
  const HomeScreen({super.key, required this.isGuest, this.userName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List _categories = [];
  List _pharmacies = [];
  int _selectedCatIndex = -1;
  Position? _userPos;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _getUserLocation();
    await _fetchData();
  }

  Future<void> _getUserLocation() async {
    try {
      _userPos = await Geolocator.getCurrentPosition();
    } catch (e) {
      // إحداثيات افتراضية في حال رفض المستخدم أو أوقف الـ GPS
      _userPos = Position(longitude: 34.4475, latitude: 31.5126, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
    }
  }

  Future<void> _fetchData() async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}home_data.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _categories = data['categories'];
            _pharmacies = data['pharmacies'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  // 💡 دالة إظهار رسالة "قريباً" (Coming Soon) الموحدة
  // 💡 دالة إظهار رسالة "قريباً" (تم إصلاح مشكلة الدائرة البيضاء)
  void _showComingSoonMsg(String featureName) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader, // نوع الأيقونة التي ستظهر في الدائرة
      title: 'قريباً جداً!',
      desc: 'ميزة ($featureName) قيد التطوير حالياً، وسيتم إضافتها في التحديث القادم للتطبيق.',
      btnOkOnPress: () {},
      btnOkColor: primaryColor,
      btnOkText: 'حسناً',
      // لتصحيح اتجاه النص ليصبح عربياً 100%
      descTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:[
                      const SizedBox(height: 10),
                      _buildTopBar(),
                      const SizedBox(height: 30),
                      _buildQuickServices(),
                      const SizedBox(height: 30),
                      _buildCategoriesSection(),
                      const SizedBox(height: 30),
                      _buildMapSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:[
        Row(
          children:[
            CircleAvatar(
              radius: 25,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(LucideIcons.user, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:[
                const Text("مرحباً بك،", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                Text(widget.isGuest ? "زائرنا العزيز" : "${widget.userName}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Stack(
            children:[
              IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell, color: Colors.black87)),
              Positioned(right: 12, top: 12, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle))),
            ],
          ),
        )
      ],
    );
  }

  // 💡 تحديث كروت الخدمات السريعة وإضافة رسالة "قريباً" لها
  Widget _buildQuickServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("خدمات سريعة", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildServiceCard("صرف وصفة", LucideIcons.fileSignature, Colors.orange, () {
              // سنبرمج رفع الوصفة لاحقاً ضمن السلة
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سيتم تفعيل رفع الوصفة من خلال السلة')));
            })),
            const SizedBox(width: 10),
            Expanded(child: _buildServiceCard("منبه الأدوية", LucideIcons.alarmClock, Colors.blue, () {
              _showComingSoonMsg("منبه الأدوية الذكي");
            })),
            const SizedBox(width: 10),
            Expanded(child: _buildServiceCard("استشارة", LucideIcons.messageCircle, primaryColor, () {
              _showComingSoonMsg("المحادثة المباشرة مع الصيدلي");
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            const Text("التصنيفات الطبية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen(userPos: _userPos))),
              child: Text("عرض الكل", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (c, i) {
              bool isSelected = _selectedCatIndex == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCatIndex = i);
                  Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen(
                    initialCategoryId: int.parse(_categories[i]['CategoryID'].toString()),
                    categoryName: _categories[i]['NameAR'],
                    userPos: _userPos,
                  )));
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isSelected ?[BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] :[],
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Text(
                      _categories[i]['NameAR'],
                      style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("أقرب الصيدليات إليك", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 15),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.grey.shade200)
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              options: MapOptions(initialCenter: LatLng(_userPos!.latitude, _userPos!.longitude), initialZoom: 13),
              children:[
                TileLayer(
                  // استخدمنا سيرفرات CartoDB القوية والجميلة (نفس المستخدمة في موقع الويب الخاص بك)
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.pharmasmart.app',
                ),
                MarkerLayer(
                  markers: _pharmacies.map((p) {
                    double lat = double.tryParse(p['Latitude']?.toString() ?? '0') ?? 0;
                    double lng = double.tryParse(p['Longitude']?.toString() ?? '0') ?? 0;
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 45, height: 45,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyProfileScreen(pharmacyData: p, userPos: _userPos)));
                        },
                          child: Center(
                            // 💡 تغيير الأيقونة على الخريطة لأيقونة صيدلية احترافية
                            child: Icon(LucideIcons.mapPin, color: primaryColor, size: 28),
                          ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // 💡 التعديل الجذري لزر الاستكشاف ليكون أيقونة صيدلية بدل السوبرماركت!
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PharmacyListScreen(userPos: _userPos!))),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 3,
            shadowColor: Colors.black26,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor.withOpacity(0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              FaIcon(FontAwesomeIcons.kitMedical, color: primaryColor, size: 20), // الأيقونة الجديدة
              const SizedBox(width: 10),
              const Text("استكشاف الصيدليات والمتاجر", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}