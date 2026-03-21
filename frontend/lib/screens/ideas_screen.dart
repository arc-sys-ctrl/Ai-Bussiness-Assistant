import 'package:flutter/material.dart';
import '../services/api_service.dart';

class IdeasScreen extends StatefulWidget {
  @override
  _IdeasScreenState createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  List<dynamic> _ideas = [];
  bool _isLoading     = true;
  bool _generating    = false;
  final _domainCtrl   = TextEditingController(text: 'fintech');

  @override
  void initState() { super.initState(); _loadIdeas(); }

  Future<void> _loadIdeas() async {
    final data = await ApiService.fetchSavedIdeas();
    if (mounted) setState(() { _ideas = data; _isLoading = false; });
  }

  Future<void> _generate() async {
    if (_domainCtrl.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final result = await ApiService.generateIdeas(_domainCtrl.text.trim());
      final newIdeas = result['ideas'] as List? ?? [];
      if (mounted) setState(() { _ideas = [...newIdeas.map((t) => {'text': t, 'domain': _domainCtrl.text}), ..._ideas]; });
      _loadIdeas();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(title: const Text("Idea Engine"), backgroundColor: Colors.transparent),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _domainCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Domain (e.g. healthtech, green energy)...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _generating ? null : _generate,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ideas.isEmpty
                  ? const Center(child: Text("Enter a domain and tap Generate.", style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _ideas.length,
                      itemBuilder: (ctx, i) {
                        final idea = _ideas[i];
                        final text = idea['idea_text'] ?? idea['text'] ?? '';
                        final domain = idea['domain'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.08), Colors.transparent]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber.withOpacity(0.2)),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                              const SizedBox(width: 8),
                              Text(domain, style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                            ]),
                            const SizedBox(height: 8),
                            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
