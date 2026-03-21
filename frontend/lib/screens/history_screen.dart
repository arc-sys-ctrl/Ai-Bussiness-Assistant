import 'package:flutter/material.dart';
import '../services/api_service.dart';
import "../widgets/aura_drawer.dart";

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.fetchChatHistory();
      if (mounted) setState(() { _history = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AuraDrawer(),
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Chat History"),
        backgroundColor: Colors.transparent,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () { setState(() => _isLoading = true); _load(); })],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.redAccent)))
              : _history.isEmpty
                  ? const Center(child: Text("No chat history yet.", style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, i) {
                        final item = _history[i];
                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                            title: Text(item['message'] ?? '', style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(item['timestamp']?.toString().substring(0, 16) ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            onTap: () => _showDetail(context, item),
                          ),
                        );
                      },
                    ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("You asked:", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text(item['message'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          const Text("AURA responded:", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Text(item['response'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
    );
  }
}
