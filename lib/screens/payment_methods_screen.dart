import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBF5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('طريقة الدفع', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.banknote, color: Colors.green.shade600, size: 30),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text('الدفع عند الاستلام (COD)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    ),
                    const Icon(LucideIcons.checkCircle2, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.creditCard, color: Colors.grey.shade400, size: 30),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text('البطاقة الائتمانية (Visa/Mastercard)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text('قريباً', style: TextStyle(color: Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.w900)),
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
}