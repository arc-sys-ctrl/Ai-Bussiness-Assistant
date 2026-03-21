import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'alerts_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _sendMessage() async {
    if (_controller.text.isEmpty) return;

    String userMsg = _controller.text;
    setState(() {
      _messages.add({"sender": "user", "text": userMsg});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    var res = await ApiService.sendMessage(userMsg);

    setState(() {
      _messages.add({"sender": "ai", "text": res});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text("ArfiAI Assistant", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
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
        decoration: BoxDecoration(
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
                padding: EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  bool isUser = _messages[index]["sender"] == "user";
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 400),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: isUser 
                            ? LinearGradient(colors: [Colors.blueAccent, Colors.blue.shade800])
                            : LinearGradient(colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(24).copyWith(
                            bottomRight: isUser ? Radius.zero : Radius.circular(24),
                            bottomLeft: !isUser ? Radius.zero : Radius.circular(24),
                          ),
                          border: !isUser ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                          ],
                        ),
                        child: Text(
                          _messages[index]["text"]!,
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 16, 
                            fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent)),
                    SizedBox(width: 10),
                    Text("Analysing data...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF1E1E1E),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent])),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/ai_logo.png', height: 60),
                  SizedBox(height: 10),
                  Text("ArfiAI Suite", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          _buildDrawerItem(Icons.dashboard, "Dashboard", () => Navigator.push(context, MaterialPageRoute(builder: (context) => DashboardScreen()))),
          _buildDrawerItem(Icons.chat, "AI Assistant", () => Navigator.pop(context)),
          _buildDrawerItem(Icons.history, "History", () => Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()))),
          _buildDrawerItem(Icons.notifications, "Alerts", () => Navigator.push(context, MaterialPageRoute(builder: (context) => AlertsScreen()))),
          _buildDrawerItem(Icons.settings, "Settings", () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen()))),
          _buildDrawerItem(Icons.business, "Profile", () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()))),
          Spacer(),
          Divider(color: Colors.white24),
          _buildDrawerItem(Icons.logout, "Logout", () => Navigator.pop(context), color: Colors.redAccent),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 15),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                  boxShadow: [
                    BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
