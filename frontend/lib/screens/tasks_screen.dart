import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  final _titleCtrl = TextEditingController();

  static const _statusColors = {
    'todo':        Colors.blueGrey,
    'in_progress': Colors.orange,
    'done':        Colors.green,
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await ApiService.fetchTasks();
    if (mounted) setState(() { _tasks = data; _isLoading = false; });
  }

  Future<void> _addTask() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    await ApiService.createTask(_titleCtrl.text.trim());
    _titleCtrl.clear();
    _load();
  }

  Future<void> _cycleStatus(int taskId, String current) async {
    const cycle = ['todo', 'in_progress', 'done'];
    final next = cycle[(cycle.indexOf(current) + 1) % cycle.length];
    await ApiService.updateTaskStatus(taskId, next);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final columns = {'todo': [], 'in_progress': [], 'done': []};
    for (var t in _tasks) columns[t['status'] ?? 'todo']?.add(t);

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      appBar: AppBar(
        title: const Text("Task Board"),
        backgroundColor: Colors.transparent,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "New task title...",
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            )),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ]),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(scrollDirection: Axis.horizontal, children: [
                  for (var status in ['todo', 'in_progress', 'done'])
                    _buildColumn(status, columns[status]!),
                ]),
        ),
      ]),
    );
  }

  Widget _buildColumn(String status, List tasks) {
    final label = {'todo': 'To Do', 'in_progress': 'In Progress', 'done': 'Done'}[status]!;
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _statusColors[status], shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            const Spacer(),
            Text('${tasks.length}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
          ]),
        ),
        const Divider(color: Colors.white12, height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: tasks.length,
            itemBuilder: (ctx, i) {
              final t = tasks[i];
              return GestureDetector(
                onTap: () => _cycleStatus(t['id'], t['status'] ?? 'todo'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    if ((t['description'] ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(t['description'], style: const TextStyle(color: Colors.white38, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}
