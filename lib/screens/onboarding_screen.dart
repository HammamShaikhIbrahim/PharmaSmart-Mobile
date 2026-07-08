// ==========================================
// استيراد المكتبات الأساسية | Importing core libraries
// ==========================================
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart'; //  إضافة مكتبة الموقع
import 'login_screen.dart';

// ==========================================
// شاشة الترحيب والتعريف بالتطبيق | Onboarding Screen
// ==========================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // ==========================================
  // متغيرات التحكم بالصفحات | Page controller variables
  // ==========================================
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  bool _isRequestingLocation =
      false; //  متغير للتحكم بحالة التحميل أثناء طلب الموقع

  final Color primaryColor = const Color(0xFF0A7A48);
  final Color bgColor = const Color(0xFFF2FBF5);

  // ==========================================
  // بيانات صفحات الترحيب | Onboarding pages data
  // ==========================================
  final List<Map<String, dynamic>> _pages = [
    {
      "title": "ابحث عن أدويتك بسهولة",
      "desc":
          "استكشف آلاف الأدوية والمنتجات الطبية، وتعرف على الصيدليات القريبة التي توفرها بضغطة زر.",
      "icon": LucideIcons.search,
    },
    {
      "title": "اطلب ووفر وقتك",
      "desc":
          "ارفع وصفتك الطبية، أضف أدويتك للسلة، وسنقوم بتجهيز طلبك فوراً للاستلام أو التوصيل.",
      "icon": LucideIcons.shoppingBag,
    },
    {
      "title": "تحديد أقرب صيدلية لك", //  تم تعديل النص ليتناسب مع طلب الموقع
      "desc":
          "سنحتاج للوصول إلى موقعك الجغرافي لنعرض لك الصيدليات الأقرب إليك لضمان سرعة التوصيل.",
      "icon": LucideIcons.mapPin,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================
  //  طلب إذن الموقع والانتهاء من الترحيب | Request location and finish onboarding
  // ==========================================
  Future<void> _requestLocationAndFinish() async {
    setState(() => _isRequestingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
      }
    } catch (e) {
      debugPrint("Location request failed: $e");
    }

    if (!mounted) return;
    setState(() => _isRequestingLocation = false);
    _finishOnboarding();
  }

  // ==========================================
  // دالة إنهاء الترحيب والذهاب لتسجيل الدخول | Finish onboarding & go to login
  // ==========================================
  Future<void> _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, _, _) => const LoginScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ==========================================
    // بناء واجهة المستخدم | Build UI
    // ==========================================
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              // ==========================================
              // عارض الصفحات | Page View
              // ==========================================
              PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPageContent(
                    title: _pages[index]["title"],
                    desc: _pages[index]["desc"],
                    icon: _pages[index]["icon"],
                  );
                },
              ),

              // ==========================================
              // زر التخطي (أعلى اليسار) | Skip Button (Top Left)
              // ==========================================
              Positioned(
                top: 20,
                left: 20,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
                  child: TextButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? null
                        : _finishOnboarding,
                    child: const Text(
                      "تخطي",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // ==========================================
              // قسم المؤشرات والزر السفلي | Bottom indicators & button
              // ==========================================
              Positioned(
                bottom: 40,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // نقاط المؤشر (Dots)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildDot(index: index),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // الزر السفلي
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isRequestingLocation
                            ? null
                            : () {
                                if (_currentPage == _pages.length - 1) {
                                  _requestLocationAndFinish(); //  استدعاء الدالة الجديدة هنا
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.ease,
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: _isRequestingLocation
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Text(
                                _currentPage == _pages.length - 1
                                    ? "الموافقة والبدء"
                                    : "التالي",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // تصميم محتوى كل صفحة | Page content design
  // ==========================================
  Widget _buildPageContent({
    required String title,
    required String desc,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(icon, size: 70, color: primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 60),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // تصميم النقاط السفلية (المؤشر) | Dot indicator design
  // ==========================================
  Widget _buildDot({required int index}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
