import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import "../widgets/aura_drawer.dart";
import '../services/api_service.dart';

class MarketScreen extends StatefulWidget {
  @override
  _MarketScreenState createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = false;
  final _topicCtrl = TextEditingController(text: 'AI business trends');
  Map<String, dynamic> _swot = {};
  bool _loadingSwot = false;

  @override
  void initState() { super.initState(); _fetchNews(); _fetchSwot(); }

  Future<void> _fetchNews() async {
    setState(() => _isLoading = true);
    final data = await ApiService.fetchMarketNews(_topicCtrl.text.trim());
    if (mounted) setState(() { _articles = data; _isLoading = false; });
  }

  Future<void> _fetchSwot() async {
    setState(() => _loadingSwot = true);
    final data = await ApiService.fetchSWOT();
    if (mounted) setState(() { _swot = data; _loadingSwot = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AuraDrawer(),
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(title: const Text("Market Intelligence"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Search bar
          Row(children: [
            Expanded(child: TextField(
              controller: _topicCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Topic (e.g. green energy, fintech)...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _fetchNews,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          ]),
          const SizedBox(height: 24),

          // News Feed
          const Text("Live News", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            for (var a in _articles) _buildArticleCard(a),

          const SizedBox(height: 28),

          // SWOT Analysis
          const Text("SWOT Analysis", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _loadingSwot
              ? const Center(child: CircularProgressIndicator())
              : _swot.isEmpty
                  ? const Text("Connect to backend to generate SWOT", style: TextStyle(color: Colors.white38))
                  : GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2,
                      children: [
                        _buildSwotCard("Strengths",     _swot['strengths'],     Colors.green),
                        _buildSwotCard("Weaknesses",    _swot['weaknesses'],    Colors.red),
                        _buildSwotCard("Opportunities", _swot['opportunities'], Colors.blue),
                        _buildSwotCard("Threats",       _swot['threats'],       Colors.orange),
                      ],
                    ),
        ]),
      ),
    );
  }

  Widget _buildArticleCard(dynamic a) {
    return GestureDetector(
      onTap: () async {
        final url = Uri.tryParse(a['url'] ?? '');
        if (url != null && await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.article_outlined, color: Colors.blueAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(a['source'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          const Icon(Icons.open_in_new, color: Colors.white24, size: 16),
        ]),
      ),
    );
  }

  Widget _buildSwotCard(String label, dynamic items, Color color) {
    final list = (items as List?)?.cast<String>() ?? [];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 6),
        for (var item in list.take(2))
          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text("• $item", style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
