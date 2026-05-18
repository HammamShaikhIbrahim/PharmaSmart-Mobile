// ==========================================
// عناصر الواجهة المشتركة | Reusable UI Components
// ==========================================
import 'package:flutter/material.dart';

class PharmaUI {
  static const Color primaryColor = Color(0xFF0A7A48);

  // ==========================================
  // التحميل الفخم | Elegant Loader
  // ==========================================
  static Widget loader() {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 2.5,
              ),
            ),
            Image.asset(
              'assets/images/logo.png',
              width: 40,
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
  // الشاشة الفارغة | Empty State UI
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
          Opacity(
            opacity: 0.12,
            child: Image.asset(
              'assets/images/logo.png',
              width: 250,
              height: 250,
              fit: BoxFit.contain,
            ),
          ),
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
