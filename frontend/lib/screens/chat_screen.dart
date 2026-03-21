import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../widgets/aura_drawer.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller      = TextEditingController();
  final ScrollController       _scrollController = ScrollController();
  // Each message: {sender, text, chat_id (nullable)}
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;
    final userMsg = _controller.text;
    setState(() {
      _messages.add({"sender": "user", "text": userMsg});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final res     = await ApiService.sendMessage(userMsg);
    final aiText  = res['response'] as String? ?? 'No response';
    final chatId  = res['chat_id'] as int?;

    setState(() {
      _messages.add({"sender": "ai", "text": aiText, "chat_id": chatId});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _giveFeedback(int? chatId, String feedback) async {
    if (chatId == null) return;
    await ApiService.rateMessage(chatId, feedback);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(feedback == 'up' ? '👍 AURA noted — response was helpful.' : '👎 AURA will learn from this.'),
      backgroundColor: feedback == 'up' ? Colors.green : Colors.orange,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AuraDrawer(),
      appBar: AppBar(
        title: const Text("AURA Assistant", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final isUser = _messages[index]["sender"] == "user";
                  final text   = _messages[index]["text"] as String? ?? '';
                  final chatId = _messages[index]["chat_id"] as int?;
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween(begin: 0, end: 1),
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                    ),
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: isUser
                                  ? const LinearGradient(colors: [Colors.blueAccent, Color(0xFF1565C0)])
                                  : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                              borderRadius: BorderRadius.circular(24).copyWith(
                                bottomRight: isUser ? Radius.zero : const Radius.circular(24),
                                bottomLeft:  !isUser ? Radius.zero : const Radius.circular(24),
                              ),
                              border: !isUser ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: Text(text, style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: isUser ? FontWeight.w500 : FontWeight.normal, height: 1.5)),
                          ),
                          // Thumbs up/down buttons for AI messages
                          if (!isUser && chatId != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.thumb_up_outlined, size: 16, color: Colors.white38),
                                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                    onPressed: () => _giveFeedback(chatId, 'up')),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.thumb_down_outlined, size: 16, color: Colors.white38),
                                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                    onPressed: () => _giveFeedback(chatId, 'down')),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
                  const SizedBox(width: 10),
                  const Text("Analysing data...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Ask AURA anything, or say 'search [topic]'...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }
}
