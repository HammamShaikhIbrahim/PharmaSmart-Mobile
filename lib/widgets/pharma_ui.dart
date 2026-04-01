import 'package:flutter/material.dart';

class PharmaUI {
  static const Color primaryColor = Color(0xFF0A7A48);

  // ==========================================
  // 1. التحميل الفخم (اللوجو ثابت وحوله دائرة تدور)
  // ==========================================
  static Widget loader() {
    return Center(
      child: SizedBox(
        width: 80, // حجم التحميل الكلي
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. الدائرة الخارجية التي تدور (الخضراء)
            const SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2.5, // خط نحيف وأنيق
              ),
            ),

            // 2. اللوجو الخاص بك (ثابت وبدون حركة نبض)
            Image.asset(
              'assets/images/logo.png', // مسار اللوجو
              width: 40, // حجم اللوجو داخل الدائرة
              height: 40,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_pharmacy,
                color: primaryColor,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 2. الشاشة الفارغة الفخمة (علامة مائية للوجو + أيقونة)
  // ==========================================
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // اللوجو كعلامة مائية شفافة في الخلفية
          Opacity(
            opacity: 0.12, // 💡 شفافية ممتازة ليكون واضحاً كعلامة مائية
            child: Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),

          // المحتوى الفعلي في المقدمة
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, size: 50, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
