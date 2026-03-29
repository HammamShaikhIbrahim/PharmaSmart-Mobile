import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'medicine_details_screen.dart';
import 'pharmacy_list_screen.dart';
import 'search_screen.dart';
import 'pharmacy_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;
  final String? userName;
  const HomeScreen({Key? key, required this.isGuest, this.userName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List _categories = [];
  List _pharmacies = [];
  List _showcase =[];
  int _selectedCatIndex = -1;
  int _showcaseIndex = 0;
  Timer? _timer;
  Position? _userPos;

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  _initData() async {
    await _getUserLocation();
    await _fetchData();
    _startShowcaseTimer();
  }

  _getUserLocation() async {
    try {
      _userPos = await Geolocator.getCurrentPosition();
    } catch (e) {
      _userPos = Position(longitude: 34.4475, latitude: 31.5126, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
    }
  }

  _fetchData() async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}home_data.php"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _categories = data['categories'];
          _pharmacies = data['pharmacies'];
          _showcase = data['showcase_medicines'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
    }
  }

  _startShowcaseTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_showcase.isNotEmpty && mounted) {
        setState(() {
          _showcaseIndex = (_showcaseIndex + 1) % _showcase.length;
        });
      }
    });
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
                      
                      _buildAutoShowcase(),
                      const SizedBox(height: 30),
                      
                      _buildCategoriesSection(),
                      const SizedBox(height: 30),
                      
                      _buildMapSection(),
                      const SizedBox(height: 20), // مسافة سفلية قبل نهاية الشاشة
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

  Widget _buildAutoShowcase() {
    if (_showcase.isEmpty) return const SizedBox();
    final item = _showcase[_showcaseIndex];
    final String imgUrl = "${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item['Image']}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("اكتشف الأدوية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => MedicineDetailsScreen(medicineId: int.parse(item['SystemMedID'].toString()), medicineName: item['Name']))),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Container(
              key: ValueKey(_showcaseIndex),
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.7)],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
                boxShadow:[
                  BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Stack(
                children:[
                  Positioned(left: -20, top: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.1))),
                  Positioned(right: -30, bottom: -30, child: CircleAvatar(radius: 50, backgroundColor: Colors.white.withOpacity(0.1))),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children:[
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(item['CategoryName'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(height: 8),
                              Text(item['Name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 10),
                              Row(
                                children:[
                                  const Text("يبدأ من ", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text("${item['Price']} ₪", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(10),
                            child: ClipOval(
                              child: Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(LucideIcons.pill, size: 40, color: primaryColor)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

  // 💡 التعديل هنا: الخريطة منفصلة تماماً عن الزر
  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text("أقرب الصيدليات إليك", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
        const SizedBox(height: 15),
        
        // مربع الخريطة
        Container(
          height: 250, // زيادة الارتفاع قليلاً لتعويض المساحة
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
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(
                  markers: _pharmacies.map((p) => Marker(
                    point: LatLng(double.parse(p['Latitude'].toString()), double.parse(p['Longitude'].toString())),
                    width: 45, height: 45,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PharmacyProfileScreen(pharmacyData: p)));
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                          boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                        ),
                        child: Center(
                          child: FaIcon(FontAwesomeIcons.hospital, color: primaryColor, size: 18),
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 20), // مسافة بين الخريطة والزر
        
        // 💡 زر الاستكشاف مفصول بالكامل أسفل الخريطة
        ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PharmacyListScreen(userPos: _userPos!))),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            elevation: 3, // إضافة ظل خفيف
            shadowColor: Colors.black26,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: primaryColor.withOpacity(0.3))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:[
              FaIcon(FontAwesomeIcons.hospital, color: primaryColor, size: 18),
              const SizedBox(width: 10),
              const Text("استكشاف قائمة الصيدليات", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}