import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 💡 إضافة المكتبة

import '../config/api_config.dart';
import 'pharmacy_list_screen.dart';
import 'search_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/pharma_ui.dart';
import 'notifications_sheet.dart';

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

  bool _hasNewNotifications = true;
  
  // 💡 متغير لحفظ الاسم وتحديثه ديناميكياً
  String _currentUserName = '';

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentUserName = widget.userName ?? '';
    _initData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _loadDynamicName(); // 💡 تحديث الاسم فور فتح الشاشة
    await _getUserLocation();
    await _fetchData();
  }

  // 💡 دالة جديدة لجلب الاسم المحدث من الذاكرة دائماً
  Future<void> _loadDynamicName() async {
    if (!widget.isGuest) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentUserName = prefs.getString('userName') ?? _currentUserName;
      });
    }
  }

  Future<void> _getUserLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _userPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } else {
        throw Exception("Permission denied");
      }
    } catch (e) {
      _userPos = Position(
        longitude: 34.4475,
        latitude: 31.5126,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تفعيل خدمة الموقع (GPS) في هاتفك أولاً'),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض صلاحية الوصول للموقع')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('صلاحيات الموقع معطلة نهائياً من إعدادات الهاتف'),
        ),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('جاري تحديد موقعك بدقة...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF0A7A48),
        ),
      );

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPos = position;
      });

      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ، لا يمكن تحديد الموقع حالياً')),
      );
    }
  }

  Future<void> _fetchData() async {
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}home_data.php"),
      );
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoonMsg(String featureName) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.noHeader,
      customHeader: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
      ),
      title: 'ميزة $featureName',
      desc:
          'هذه الميزة قيد التطوير حالياً، وتعمل فرقنا على تجهيزها بأفضل شكل لتكون متاحة في التحديث القادم! ',
      btnOkOnPress: () {},
      btnOkColor: primaryColor,
      btnOkText: 'فهمت ذلك',
      buttonsBorderRadius: BorderRadius.circular(15),
      descTextStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        height: 1.5,
      ),
    ).show();
  }

  void _zoomIn() {
    final double currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom + 1).clamp(1.0, 18.0),
    );
  }

  void _zoomOut() {
    final double currentZoom = _mapController.camera.zoom;
    _mapController.move(
      _mapController.camera.center,
      (currentZoom - 1).clamp(1.0, 18.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 تحديث الاسم عند بناء الشاشة للضمان
    _loadDynamicName();

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? PharmaUI.loader()
          : SafeArea(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        _buildTopBar(),
                        if (widget.isGuest) _buildGuestBanner(),
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
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(LucideIcons.user, color: primaryColor, size: 28),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "مرحباً بك،",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.isGuest ? "زائرنا العزيز" : _currentUserName, // 💡 استخدام الاسم المحدث
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _hasNewNotifications = false);
                  NotificationsSheet.show(context);
                },
                icon: const Icon(LucideIcons.bell, color: Colors.black87),
              ),
              if (_hasNewNotifications)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuestBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.userCheck,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "سجل لتتمكن من الطلب!",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "احفظ أدويتك وتتبع طلباتك بسهولة.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const LoginScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "دخول",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => const SignupScreen(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          side: BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "حساب جديد",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServices() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "خدمات سريعة",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
                "صرف وصفة",
                const FaIcon(
                  FontAwesomeIcons.filePrescription,
                  color: Colors.orange,
                  size: 22,
                ),
                Colors.orange,
                () {
                  AwesomeDialog(
                    context: context,
                    dialogType: DialogType.info,
                    title: 'كيف أصرف وصفتي؟',
                    desc:
                        'ابحث عن الأدوية المكتوبة في الوصفة، أضفها للسلة، وسيقوم النظام تلقائياً بطلب صورة الوصفة الطبية منك لإتمام الطلب!',
                    btnOkColor: primaryColor,
                    btnOkText: 'البحث عن الأدوية',
                    btnOkOnPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => SearchScreen(userPos: _userPos),
                        ),
                      );
                    },
                  ).show();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceCard(
                "منبه الأدوية",
                const FaIcon(
                  FontAwesomeIcons.clockRotateLeft,
                  color: Colors.blue,
                  size: 22,
                ),
                Colors.blue,
                () => _showComingSoonMsg("منبه الأدوية الذكي"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildServiceCard(
                "استشارة",
                FaIcon(
                  FontAwesomeIcons.userDoctor,
                  color: primaryColor,
                  size: 22,
                ),
                primaryColor,
                () => _showComingSoonMsg(
                  "المحادثات المباشرة",
                ), 
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    Widget iconWidget,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: iconWidget,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "التصنيفات الطبية",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => SearchScreen(userPos: _userPos),
                ),
              ),
              child: Text(
                "عرض الكل",
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => SearchScreen(
                        initialCategoryId: int.parse(
                          _categories[i]['CategoryID'].toString(),
                        ),
                        categoryName: _categories[i]['NameAR'],
                        userPos: _userPos,
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _categories[i]['NameAR'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "أقرب الصيدليات إليك",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(
                      _userPos!.latitude,
                      _userPos!.longitude,
                    ),
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      userAgentPackageName: 'com.pharmasmart.app',
                    ),
                    MarkerLayer(
                      markers: _pharmacies.map((p) {
                        double lat =
                            double.tryParse(p['Latitude']?.toString() ?? '0') ??
                                0;
                        double lng =
                            double.tryParse(
                              p['Longitude']?.toString() ?? '0',
                            ) ??
                                0;
                        return Marker(
                          point: LatLng(lat, lng),
                          width: 45,
                          height: 45,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmacyProfileScreen(
                                    pharmacyData: p,
                                    userPos: _userPos,
                                  ),
                                ),
                              );
                            },
                            child: Center(
                              child: FaIcon(
                                FontAwesomeIcons.houseMedical,
                                color: primaryColor,
                                size: 26,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "homeGpsBtn",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _goToMyLocation,
                        child: const Icon(
                          LucideIcons.navigation,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      FloatingActionButton(
                        heroTag: "homeZoomInBtn",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomIn,
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 5),
                      FloatingActionButton(
                        heroTag: "homeZoomOutBtn",
                        mini: true,
                        backgroundColor: Colors.white,
                        onPressed: _zoomOut,
                        child: const Icon(
                          LucideIcons.minus,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // 💡 التعديل هنا: تصميم الزر كباقي التطبيق وتغيير النص
        ElevatedButton(
          onPressed: () async {
            final selectedLocation = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (c) => PharmacyListScreen(userPos: _userPos!),
              ),
            );
            if (selectedLocation != null && selectedLocation is LatLng) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
              _mapController.move(selectedLocation, 16.0);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // اللون الأخضر الأساسي
            foregroundColor: Colors.white, // لون النص والأيقونة
            elevation: 5,
            shadowColor: primaryColor.withOpacity(0.4),
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.houseMedical,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 10),
              Text(
                "استكشاف الصيدليات",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}