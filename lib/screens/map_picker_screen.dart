// ==========================================
// 1. استدعاء المكتبات الأساسية للتطبيق
// ==========================================
import 'package:flutter/material.dart'; 
import 'package:flutter_map/flutter_map.dart'; 
import 'package:latlong2/latlong.dart'; 
import 'package:lucide_icons/lucide_icons.dart'; 
import 'package:geolocator/geolocator.dart'; 

// ==========================================
// 2. إنشاء كلاس الشاشة 
// ==========================================
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  
  // نقطة البداية الافتراضية للخريطة
  LatLng _selectedLocation = const LatLng(32.3194, 35.0244); 
  final MapController _mapController = MapController();

  // ==========================================
  // 3. دالة جلب الموقع التلقائي عبر الـ GPS
  // ==========================================
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تفعيل خدمة الموقع (GPS) في هاتفك', textDirection: TextDirection.rtl)),
      );
      return; 
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض صلاحية الوصول للموقع', textDirection: TextDirection.rtl)),
        );
        return; 
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صلاحيات الموقع معطلة نهائياً من الإعدادات', textDirection: TextDirection.rtl)),
      );
      return;
    }

    // جلب الموقع بدقة عالية
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(_selectedLocation, 15.0);
  }

  // ==========================================
  // 4. دوال التكبير والتصغير 
  // ==========================================
  void _zoomIn() {
    final double currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(1.0, 18.0));
  }

  void _zoomOut() {
    final double currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(1.0, 18.0));
  }

  // ==========================================
  // 5. بناء واجهة الشاشة
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديد موقع التوصيل', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0A7A48), 
        centerTitle: true, 
      ),
      
      body: Stack(
        children:[
          // ------------------------------------------
          // أ) الخريطة التفاعلية 
          // ------------------------------------------
          FlutterMap(
            mapController: _mapController, 
            options: MapOptions(
              initialCenter: _selectedLocation, 
              initialZoom: 13.0, 
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLocation = point;
                });
              },
            ),
            children:[
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.pharmasmart.app',
              ),
              
              // ------------------------------------------
              // طبقة رسم الدبوس (تم تعديله ليكون سادة وجميل)
              // ------------------------------------------
              MarkerLayer(
                markers:[
                  Marker(
                    point: _selectedLocation, 
                    width: 50, 
                    height: 50, 
                    alignment: Alignment.topCenter, // لكي يكون رأس الدبوس بالضبط على النقطة المحددة
                    child: const Icon(
                      LucideIcons.mapPin, // الأيقونة السادة
                      color: Color(0xFF0A7A48), // اللون الأخضر الأساسي للتطبيق
                      size: 45, // الحجم
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ------------------------------------------
          // ب) رسالة توضيحية علوية
          // ------------------------------------------
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), 
                borderRadius: BorderRadius.circular(15), 
                boxShadow: const[BoxShadow(color: Colors.black12, blurRadius: 10)], 
              ),
              child: const Row(
                children:[
                  Icon(LucideIcons.info, color: Color(0xFF0A7A48)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'حرك الخريطة، واضغط على موقعك بدقة لتثبيت الدبوس.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ------------------------------------------
          // ج) أزرار التحكم الجانبية (Zoom & GPS)
          // ------------------------------------------
          Positioned(
            bottom: 100, 
            right: 15,   
            child: Column(
              children:[
                FloatingActionButton(
                  heroTag: "gpsBtn", 
                  backgroundColor: Colors.white,
                  onPressed: _getCurrentLocation, 
                  child: const Icon(LucideIcons.navigation, color: Colors.blue),
                ),
                const SizedBox(height: 15), 
                
                FloatingActionButton(
                  heroTag: "zoomInBtn",
                  mini: true, 
                  backgroundColor: Colors.white,
                  onPressed: _zoomIn,
                  child: const Icon(LucideIcons.plus, color: Colors.black87),
                ),
                const SizedBox(height: 5),
                
                FloatingActionButton(
                  heroTag: "zoomOutBtn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: _zoomOut,
                  child: const Icon(LucideIcons.minus, color: Colors.black87),
                ),
              ],
            ),
          ),

          // ------------------------------------------
          // د) زر التأكيد والاعتماد 
          // ------------------------------------------
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _selectedLocation);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A7A48), 
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                elevation: 5,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Text(
                    'تأكيد الموقع المختار',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Icon(LucideIcons.checkCircle, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}