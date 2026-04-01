import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'pharmacy_list_screen.dart';
import 'search_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
<<<<<<< Updated upstream
=======
import 'notifications_sheet.dart'; // 💡 حل المشكلة الأولى: إضافة الاستدعاء
>>>>>>> Stashed changes

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
  String? _displayName;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  final MapController _mapController = MapController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _displayName = widget.userName;
    _initData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNameFromPrefs();
  }

  Future<void> _loadNameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedName = prefs.getString('userName');
    if (savedName != null && mounted) {
      setState(() {
        _displayName = savedName.split(' ')[0];
      });
    }
  }

  Future<void> _initData() async {
    await _getUserLocation();
    await _fetchData();
    await _loadNameFromPrefs();
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
            desiredAccuracy: LocationAccuracy.high);
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
          headingAccuracy: 0);
    }
  }

  Future<void> _goToMyLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تفعيل خدمة الموقع (GPS) في هاتفك أولاً')));
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _userPos = position);
    _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showComingSoonMsg(String featureName) {
    AwesomeDialog(
            context: context,
            dialogType: DialogType.noHeader,
            title: 'قريباً جداً!',
            desc: 'ميزة ($featureName) قيد التطوير حالياً.',
            btnOkColor: primaryColor,
            btnOkText: 'حسناً')
        .show();
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
                child: RefreshIndicator(
                  onRefresh: _initData,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
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
                child: Icon(LucideIcons.user, color: primaryColor, size: 28)),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("مرحباً بك،",
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text(widget.isGuest ? "زائرنا العزيز" : "$_displayName",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
<<<<<<< Updated upstream
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
                onPressed: () {},
                icon: const Icon(LucideIcons.bell, color: Colors.black87),
              ),
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
=======
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
              ]),
          child: IconButton(
              onPressed: () => NotificationsSheet.show(context),
              icon: const Icon(LucideIcons.bell, color: Colors.black87)),
>>>>>>> Stashed changes
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
          border: Border.all(color: primaryColor.withOpacity(0.2))),
      child: Row(
        children: [
          Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
              child: const FaIcon(FontAwesomeIcons.userCheck,
                  color: Color(0xFFF0A7A4), size: 22)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("سجل لتتمكن من الطلب!",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                const Text("احفظ أدويتك وتتبع طلباتك بسهولة.",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const LoginScreen())),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: const Text("دخول",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 8),
                    OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const SignupScreen())),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryColor)),
                        child: Text("حساب جديد",
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold))),
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
        const Text("خدمات سريعة",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
                child: _buildServiceCard(
                    "صرف وصفة",
                    const FaIcon(FontAwesomeIcons.filePrescription,
                        color: Colors.orange, size: 22),
                    Colors.orange, () {
              AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  title: 'كيف أصرف وصفتي؟',
                  desc: 'ابحث عن الأدوية، أضفها للسلة، وسنطلب منك صورة الوصفة.',
                  btnOkColor: primaryColor,
                  btnOkText: 'البحث عن الأدوية',
                  btnOkOnPress: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) =>
                              SearchScreen(userPos: _userPos)))).show();
            })),
            const SizedBox(width: 10),
            Expanded(
                child: _buildServiceCard(
                    "منبه الأدوية",
                    const FaIcon(FontAwesomeIcons.clockRotateLeft,
                        color: Colors.blue, size: 22),
                    Colors.blue,
                    () => _showComingSoonMsg("منبه الأدوية الذكي"))),
            const SizedBox(width: 10),
            Expanded(
                child: _buildServiceCard(
                    "استشارة",
                    FaIcon(FontAwesomeIcons.userDoctor,
                        color: primaryColor, size: 22),
                    primaryColor,
                    () => _showComingSoonMsg("المحادثة المباشرة"))),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(
      String title, Widget icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100)),
        child: Column(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: icon),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))
        ]),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("التصنيفات الطبية",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => SearchScreen(userPos: _userPos))),
              child: Text("عرض الكل",
                  style: TextStyle(
                      color: primaryColor, fontWeight: FontWeight.bold))),
        ]),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _categories.length,
            itemBuilder: (c, i) => GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => SearchScreen(
                          initialCategoryId:
                              int.parse(_categories[i]['CategoryID'].toString()),
                          categoryName: _categories[i]['NameAR'],
                          userPos: _userPos))),
              child: Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200)),
                  child: Center(
                      child: Text(_categories[i]['NameAR'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("أقرب الصيدليات إليك",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 15),
        Container(
          height: 250,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                  initialCenter: LatLng(_userPos!.latitude, _userPos!.longitude),
                  initialZoom: 13),
              children: [
                TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png'),
                MarkerLayer(
                    markers: _pharmacies
                        .map((p) => Marker(
                            point: LatLng(
                                double.parse(p['Latitude'].toString()),
                                double.parse(p['Longitude'].toString())),
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            PharmacyProfileScreen(
                                                pharmacyData: p,
                                                userPos: _userPos))),
                                child: Center(
                                    child: FaIcon(FontAwesomeIcons.houseMedical,
                                        color: primaryColor, size: 26)))))
                        .toList()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => PharmacyListScreen(userPos: _userPos!))),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: primaryColor.withOpacity(0.3)))),
            child: const Text("استكشاف الصيدليات والمتاجر",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
      ],
    );
  }
}