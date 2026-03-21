import 'package:flutter/material.dart';
import '../services/api_service.dart';

class OKRScreen extends StatefulWidget {
  @override
  _OKRScreenState createState() => _OKRScreenState();
}

class _OKRScreenState extends State<OKRScreen> {
  List<dynamic> _okrs = [];
  bool _isLoading = true;
  final _objectiveCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await ApiService.fetchOKRs();
    if (mounted) setState(() { _okrs = data; _isLoading = false; });
  }

  Future<void> _addOKR() async {
    if (_objectiveCtrl.text.trim().isEmpty) return;
    await ApiService.createOKR(_objectiveCtrl.text.trim(), [
      {"text": "Key Result 1 — Define metrics", "progress": 0},
      {"text": "Key Result 2 — Execute strategy", "progress": 0},
      {"text": "Key Result 3 — Validate outcome", "progress": 0},
    ]);
    _objectiveCtrl.clear();
    _load();
  }

  Future<void> _nudgeProgress(int okrId, List krs, int krIndex) async {
    final updated = List<Map<String, dynamic>>.from(krs.map((k) => Map<String, dynamic>.from(k)));
    int current = (updated[krIndex]['progress'] as num?)?.toInt() ?? 0;
    updated[krIndex]['progress'] = (current + 25) > 100 ? 0 : current + 25;
    await ApiService.updateOKR(okrId, updated);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(title: const Text("OKR Tracker"), backgroundColor: Colors.transparent,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _objectiveCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "New Objective...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.flag_outlined, color: Colors.blueAccent),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addOKR,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _okrs.isEmpty
                  ? const Center(child: Text("No OKRs yet. Add one above.", style: TextStyle(color: Colors.white38)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _okrs.length,
                      itemBuilder: (ctx, i) => _buildOKRCard(_okrs[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _buildOKRCard(dynamic okr) {
    final krs = (okr['key_results'] as List?) ?? [];
    final progress = (okr['overall_progress'] as num?)?.toDouble() ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(okr['objective'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress / 100, minHeight: 8, backgroundColor: Colors.white12, color: _progressColor(progress)),
          )),
          const SizedBox(width: 10),
          Text('${progress.toInt()}%', style: TextStyle(color: _progressColor(progress), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
        const SizedBox(height: 14),
        for (int j = 0; j < krs.length; j++) _buildKR(okr['id'], krs, j),
      ]),
    );
  }

  Widget _buildKR(int okrId, List krs, int idx) {
    final kr = krs[idx];
    final p  = (kr['progress'] as num?)?.toInt() ?? 0;
    return GestureDetector(
      onTap: () => _nudgeProgress(okrId, krs, idx),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(p == 100 ? Icons.check_circle : Icons.radio_button_unchecked, color: p == 100 ? Colors.green : Colors.white38, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(kr['text'] ?? '', style: TextStyle(color: p == 100 ? Colors.green : Colors.white70, fontSize: 13, decoration: p == 100 ? TextDecoration.lineThrough : null))),
          Text('$p%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }

  Color _progressColor(double p) {
    if (p >= 80) return Colors.green;
    if (p >= 50) return Colors.orange;
    return Colors.redAccent;
  }
}
