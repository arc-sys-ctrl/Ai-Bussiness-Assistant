import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "../widgets/aura_drawer.dart";
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _integrations = [];
  List<dynamic> _apiKeys      = [];
  Map<String, dynamic> _subscription = {};
  final _slackCtrl = TextEditingController();
  bool _loading    = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.fetchIntegrations(),
      ApiService.fetchApiKeys(),
      ApiService.fetchSubscription(),
    ]);
    if (mounted) setState(() {
      _integrations  = results[0] as List;
      _apiKeys       = results[1] as List;
      _subscription  = results[2] as Map<String, dynamic>;
      _loading       = false;
    });
  }

  Future<void> _saveSlack() async {
    if (_slackCtrl.text.trim().isEmpty) return;
    await ApiService.saveSlackIntegration(_slackCtrl.text.trim());
    _slackCtrl.clear();
    _load();
  }

  Future<void> _generateApiKey() async {
    final key = await ApiService.createApiKey('AURA Key ${DateTime.now().millisecondsSinceEpoch}');
    if (mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("API Key Created", style: TextStyle(color: Colors.white)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("Store this key securely — shown only once:", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),
          SelectableText(key, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: key)); Navigator.pop(context); }, child: const Text("Copy & Close")),
        ],
      ));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AuraDrawer(),
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.white38,
          tabs: const [Tab(text: "Integrations"), Tab(text: "Developer"), Tab(text: "Plan")],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tabs, children: [
              _buildIntegrationsTab(),
              _buildDeveloperTab(),
              _buildPlanTab(),
            ]),
    );
  }

  // ─── Integrations ───────────────────────────────────────────────── #
  Widget _buildIntegrationsTab() {
    final hasSlack = _integrations.any((i) => i['type'] == 'slack' && i['enabled'] == true);
    return ListView(padding: const EdgeInsets.all(20), children: [
      _sectionHeader("Slack", Icons.webhook_outlined),
      const Text("Receive AURA alerts directly in your Slack channel.", style: TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 12),
      if (hasSlack)
        _buildStatusBadge("Slack Connected", Colors.green)
      else ...[
        TextField(
          controller: _slackCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Slack Incoming Webhook URL",
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true, fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.link, color: Colors.white38),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _saveSlack,
          icon: const Icon(Icons.save, size: 18, color: Colors.white),
          label: const Text("Save Slack Webhook", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ],
      const SizedBox(height: 24),
      _sectionHeader("Inbound Webhook", Icons.input_outlined),
      const Text("POST JSON to /api/v1/integrations/webhook — it will appear as an alert.", style: TextStyle(color: Colors.white38, fontSize: 12)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
        child: const SelectableText("POST /api/v1/integrations/webhook", style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12)),
      ),
    ]);
  }

  // ─── Developer ──────────────────────────────────────────────────── #
  Widget _buildDeveloperTab() {
    return ListView(padding: const EdgeInsets.all(20), children: [
      _sectionHeader("API Keys", Icons.vpn_key_outlined),
      const Text("Use your API key in X-API-Key header for programmatic access.", style: TextStyle(color: Colors.white38, fontSize: 13)),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _generateApiKey,
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
        label: const Text("Generate New Key", style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
      const SizedBox(height: 20),
      if (_apiKeys.isEmpty)
        const Text("No keys generated yet.", style: TextStyle(color: Colors.white38))
      else
        for (var k in _apiKeys)
          ListTile(
            leading: const Icon(Icons.key, color: Colors.purpleAccent),
            title: Text(k['label'] ?? 'Key', style: const TextStyle(color: Colors.white)),
            subtitle: Text(k['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ),
    ]);
  }

  // ─── Plan ───────────────────────────────────────────────────────── #
  Widget _buildPlanTab() {
    final plan     = _subscription['plan'] ?? 'free';
    final features = (_subscription['features'] as Map?) ?? {};
    return ListView(padding: const EdgeInsets.all(20), children: [
      _sectionHeader("Current Plan", Icons.workspace_premium_outlined),
      const SizedBox(height: 12),
      _buildStatusBadge(plan.toUpperCase(), _planColor(plan)),
      const SizedBox(height: 20),
      for (var entry in features.entries)
        ListTile(
          dense: true,
          leading: const Icon(Icons.check, color: Colors.green, size: 18),
          title: Text(_featureLabel(entry.key, entry.value), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ),
      const SizedBox(height: 24),
      if (plan == 'free') ...[
        const Text("Upgrade to unlock unlimited queries, integrations, and team collaboration.", style: TextStyle(color: Colors.white38, fontSize: 13)),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text("Upgrade to Pro", style: TextStyle(color: Colors.white)),
        ),
      ],
    ]);
  }

  Widget _sectionHeader(String label, IconData icon) {
    return Row(children: [
      Icon(icon, color: Colors.blueAccent, size: 20),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  Color _planColor(String plan) {
    switch (plan) { case 'pro': return Colors.blueAccent; case 'enterprise': return Colors.amber; default: return Colors.grey; }
  }

  String _featureLabel(String key, dynamic value) {
    final v = value == -1 ? 'Unlimited' : value.toString();
    switch (key) {
      case 'queries_per_month': return "AI Queries / Month: $v";
      case 'integrations':      return "Integrations: $v";
      case 'members':           return "Team Members: $v";
      default:                  return "$key: $v";
    }
  }
}
