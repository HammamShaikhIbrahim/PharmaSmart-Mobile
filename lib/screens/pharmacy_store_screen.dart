import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/cart_helper.dart';

class PharmacyStoreScreen extends StatefulWidget {
  final int pharmacyId;
  final String pharmacyName;
  const PharmacyStoreScreen({super.key, required this.pharmacyId, required this.pharmacyName});

  @override
  State<PharmacyStoreScreen> createState() => _PharmacyStoreScreenState();
}

class _PharmacyStoreScreenState extends State<PharmacyStoreScreen> {
  List _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final res = await http.get(Uri.parse("${ApiConfig.baseUrl}pharmacy_inventory.php?pharmacy_id=${widget.pharmacyId}"));
    final data = jsonDecode(res.body);
    setState(() { _items = data['items']; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.pharmacyName), backgroundColor: const Color(0xFF0A7A48)),
        body: _loading 
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 10, mainAxisSpacing: 10),
              itemCount: _items.length,
              itemBuilder: (c, i) {
                var item = _items[i];
                return Card(
                  child: Column(
                    children: [
                      Image.network("${ApiConfig.baseUrl.replaceAll('api/', '')}uploads/medicines/${item['Image']}", height: 100, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(item['Name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text("${item['Price']} ₪", style: const TextStyle(color: Color(0xFF0A7A48), fontWeight: FontWeight.bold)),
                            ElevatedButton(
                              onPressed: () {
                                try {
                                  debugPrint("🛒 محاولة إضافة: StockID=${item['StockID']}, SystemMedID=${item['SystemMedID']}");
                                  CartHelper.addToCart(
                                    context: context,
                                    stockId: int.parse(item['StockID'].toString()),
                                    systemMedId: int.parse(item['SystemMedID'].toString()),
                                    medicineName: item['Name'],
                                    image: item['Image'] ?? 'default_med.png',
                                    price: double.parse(item['Price'].toString()),
                                    pharmacistId: widget.pharmacyId,
                                    pharmacyName: widget.pharmacyName,
                                    isControlled: item['IsControlled'].toString() == "1",
                                  );
                                } catch (e) {
                                  debugPrint("❌ خطأ في الإضافة: $e");
                                  debugPrint("📦 بيانات العنصر: $item");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0A7A48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text("إضافة للسلة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      ),
    );
  }
}