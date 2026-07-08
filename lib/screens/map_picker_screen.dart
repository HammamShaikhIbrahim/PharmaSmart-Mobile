// ==========================================
// استيراد المكتبات الأساسية | Importing core libraries
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

// ==========================================
// شاشة التقاط الموقع الجغرافي | Map Picker Screen
// ==========================================
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  // ==========================================
  // المتغيرات وتحديد المركز الافتراضي | Variables & default center
  // ==========================================
  LatLng? _selectedLocation;
  final LatLng _palestineCenter = const LatLng(31.90, 35.20);
  final MapController _mapController = MapController();

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  // ==========================================
  // دالة جلب الموقع التلقائي عبر الـ GPS | Fetch current GPS location
  // ==========================================
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء تفعيل خدمة الموقع (GPS) في هاتفك'),
          backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('تم رفض صلاحية الوصول للموقع'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('صلاحيات الموقع معطلة نهائياً من الإعدادات'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('جاري تحديد موقعك بدقة...'),
          backgroundColor: primaryColor,
          duration: const Duration(seconds: 1),
        ),
      );
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _selectedLocation = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(_selectedLocation!, 15.0);
  }

  // ==========================================
  // دوال التكبير والتصغير | Zoom In & Out Functions
  // ==========================================
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
    // ==========================================
    // بناء واجهة الخريطة | Build Map UI
    // ==========================================
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تحديد موقع التوصيل',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: Stack(
          children: [
            // ==========================================
            // الخريطة التفاعلية والطبقات | Interactive map and layers
            // ==========================================
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _palestineCenter,
                initialZoom: 8.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedLocation = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  userAgentPackageName: 'com.pharmasmart.app',
                ),

                if (_selectedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLocation!,
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const Positioned(
                                bottom: 30,
                                child: Icon(
                                  Icons.location_on,
                                  color: Color(0xFF0A7A48),
                                  size: 45,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            // ==========================================
            // رسالة إرشادية علوية | Top instructional message
            // ==========================================
            Positioned(
              top: 15,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.info, color: primaryColor, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'حرك الخريطة، واضغط على موقعك بدقة لتثبيت الدبوس.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // أزرار التحكم بالخريطة (Zoom & GPS) | Map control buttons
            // ==========================================
            Positioned(
              bottom: 120,
              right: 20,
              child: Column(
                children: [
                  _buildFloatingBtn(
                    icon: LucideIcons.navigation,
                    color: Colors.blue.shade600,
                    onTap: _getCurrentLocation,
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSmallBtn(icon: LucideIcons.plus, onTap: _zoomIn),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                          indent: 8,
                          endIndent: 8,
                        ),
                        _buildSmallBtn(
                          icon: LucideIcons.minus,
                          onTap: _zoomOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ==========================================
        // زر التأكيد السفلي | Bottom confirmation button
        // ==========================================
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton(
              onPressed: _selectedLocation == null
                  ? null
                  : () {
                      Navigator.pop(context, _selectedLocation);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: _selectedLocation == null ? 0 : 5,
                shadowColor: primaryColor.withOpacity(0.4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedLocation == null
                        ? 'الرجاء وضع دبوس على الخريطة'
                        : 'تأكيد الموقع المختار',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: _selectedLocation == null
                          ? Colors.grey.shade500
                          : Colors.white,
                    ),
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(width: 10),
                    const Icon(
                      LucideIcons.checkCircle2,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // تصميم الأزرار الجانبية | Design of floating buttons
  // ==========================================
  Widget _buildFloatingBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildSmallBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 45,
        height: 45,
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }
}
