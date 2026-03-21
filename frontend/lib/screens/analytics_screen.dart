import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/aura_drawer.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> _forecast = {};
  List<dynamic> _anomalies = [];
  Map<String, dynamic> _aiStatus = {};
  bool _loading = true;

  // Sample historical data (real apps submit actual revenue values from DB)
  final List<double> _historical = [42000, 44500, 43200, 47800, 52100, 49800, 58200];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.fetchForecast(_historical),
      ApiService.fetchAnomalies(_historical),
      ApiService.fetchAIStatus(),
    ]);
    if (mounted) {
      setState(() {
        _forecast   = results[0] as Map<String, dynamic>;
        _anomalies  = results[1] as List;
        _aiStatus   = results[2] as Map<String, dynamic>;
        _loading    = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      drawer: const AuraDrawer(),
      appBar: AppBar(title: const Text("Analytics"), backgroundColor: Colors.transparent,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Revenue Forecast
                const Text("Revenue Forecast", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildForecastCard(),

                const SizedBox(height: 24),

                // Anomaly Detection
                const Text("Anomaly Detection", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _anomalies.isEmpty
                    ? _buildInfoCard("No anomalies detected in current dataset.", Colors.green)
                    : Column(children: _anomalies.map<Widget>((a) => _buildAnomalyCard(a)).toList()),

                const SizedBox(height: 24),

                // AI Status
                const Text("AI Neural Network Status", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildAIStatusCard(),
              ]),
            ),
    );
  }

  Widget _buildForecastCard() {
    final forecast = (_forecast['forecast'] as List?)?.cast<num>() ?? [];
    final trend    = _forecast['trend'] ?? 'flat';
    final r2       = (_forecast['r2'] as num?)?.toDouble() ?? 0.0;
    final trendColor = trend == 'growing' ? Colors.green : trend == 'declining' ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(trend == 'growing' ? Icons.trending_up : trend == 'declining' ? Icons.trending_down : Icons.trending_flat, color: trendColor),
          const SizedBox(width: 8),
          Text("Trend: ${trend.toUpperCase()}", style: TextStyle(color: trendColor, fontWeight: FontWeight.bold)),
          const Spacer(),
          Text("R² ${r2.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
        const SizedBox(height: 16),
        const Text("Next 4 Periods Forecast:", style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          for (int i = 0; i < forecast.length; i++)
            Column(children: [
              Text("Q+${i+1}", style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 4),
              Text("\$${(forecast[i] / 1000).toStringAsFixed(1)}k", style: TextStyle(color: trendColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
        ]),
        const SizedBox(height: 14),
        const Text("Historical:", style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        _buildBarChart(_historical),
      ]),
    );
  }

  Widget _buildBarChart(List<double> data) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: data.map((v) {
        final ratio = max > 0 ? v / max : 0.0;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 28, height: 60 * ratio, color: Colors.blueAccent.withOpacity(0.7), margin: const EdgeInsets.symmetric(horizontal: 2)),
          const SizedBox(height: 4),
          Text("\$${(v / 1000).toStringAsFixed(0)}k", style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ]);
      }).toList(),
    );
  }

  Widget _buildAnomalyCard(dynamic a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${(a['type'] as String).toUpperCase()} at index ${a['index']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("Value: \$${a['value']} — Z-score: ${a['z_score']}", style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ])),
      ]),
    );
  }

  Widget _buildAIStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.memory, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(_aiStatus['model'] ?? 'AURA Neural Net', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 12),
        _statusRow("Architecture", _aiStatus['architecture'] ?? 'InputLayer → Hidden → OutputLayer'),
        _statusRow("Intent Classes", _aiStatus['intents']?.toString() ?? '16'),
        _statusRow("Weights Updated", _aiStatus['weights_updated']?.toString().substring(0, 10) ?? 'Not trained'),
      ]),
    );
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Text("$label: ", style: const TextStyle(color: Colors.white38, fontSize: 12)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      ]),
    );
  }

  Widget _buildInfoCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 10), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70)))]),
    );
  }
}
