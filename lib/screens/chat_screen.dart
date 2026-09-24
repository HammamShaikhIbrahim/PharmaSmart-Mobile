import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ChatScreen extends StatefulWidget {
  final int pharmacistId;
  final String pharmacyName;

  const ChatScreen({super.key, required this.pharmacistId, required this.pharmacyName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  List _messages = [];
  bool _isLoading = true;
  String _patientId = '0';

  final Color primaryColor = const Color(0xFF0A7A48);

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    final prefs = await SharedPreferences.getInstance();
    _patientId = prefs.getString('userId') ?? '0';
    
    await _loadMessages();
    setState(() => _isLoading = false);

    // تفعيل Polling (جلب الرسائل كل 3 ثوانٍ)
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMessages();
    });
  }

  Future<void> _loadMessages() async {
    try {
      final res = await http.get(Uri.parse(
          "${ApiConfig.baseUrl}get_messages.php?patient_id=$_patientId&pharmacist_id=${widget.pharmacistId}&user_type=Patient"));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          if (mounted) {
            setState(() {
              _messages = data['messages'];
            });
            _scrollToBottom();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}send_message.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "patient_id": int.parse(_patientId),
          "pharmacist_id": widget.pharmacistId,
          "sender_type": "Patient",
          "message": text
        }),
      );

      if (res.statusCode == 200) {
        _loadMessages();
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2FBF5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(widget.pharmacyName, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 16)),
              const Text("نشط الآن", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowRight, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A7A48)))
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final bool isMe = msg['SenderType'] == 'Patient';

                        return Align(
                          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? primaryColor : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                              ),
                              border: isMe ? null : Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                Text(msg['MessageText'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(msg['FormattedTime'] ?? '', style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 9)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildInputArea(),
                ],
              ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "اكتب رسالتك واستشر طبيبك...",
                border: InputBorder.none,
                hintStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
              ),
              onSubmitted: (_) => _onSendPressed(),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.plusCircle, color: Colors.grey),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _onSendPressed() {
    _sendMessage();
  }
}