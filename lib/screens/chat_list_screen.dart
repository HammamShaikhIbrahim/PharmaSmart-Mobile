import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'chat_screen.dart';
import '../widgets/pharma_ui.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isLoading = true;
  List _chats = [];
  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  Future<void> _fetchChats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '0';

    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}get_patient_chats.php?patient_id=$userId"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          setState(() {
            _chats = data['chats'];
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error fetching chats: $e");
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text("استشاراتي الطبية", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? Center(child: PharmaUI.loader())
            : _chats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _chats.length,
                    itemBuilder: (context, index) {
                      final chat = _chats[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: CircleAvatar(
                            backgroundColor: primaryColor.withOpacity(0.1),
                            child: Icon(LucideIcons.messageSquare, color: primaryColor),
                          ),
                          title: Text(chat['PharmacyName'], style: const TextStyle(fontWeight: FontWeight.w900)),
                          subtitle: Text(chat['LastMessage'] ?? 'اضغط لبدء المحادثة...', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          trailing: chat['UnreadCount'] != null && int.parse(chat['UnreadCount'].toString()) > 0
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                  child: Text(chat['UnreadCount'].toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              : const Icon(LucideIcons.chevronLeft, color: Colors.grey),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => ChatScreen(
                                  pharmacistId: int.parse(chat['PharmacistID'].toString()),
                                  pharmacyName: chat['PharmacyName'],
                                ),
                              ),
                            ).then((_) => _fetchChats());
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return PharmaUI.emptyState(
      icon: LucideIcons.messageSquareDashed,
      title: 'لا يوجد استشارات سابقة',
      subtitle: 'يمكنك فتح أي صيدلية والضغط على زر "تواصل مع الصيدلي" لبدء الاستشارة الفورية!',
    );
  }
}