import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});
  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  Map<String, dynamic>? _data;
  int _page = 1;
  final _pageSize = 20;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient(context.read<AuthStore>());
    final list = await api.listAssignments(page: _page, pageSize: _pageSize);
    if (!mounted) return;
    setState(() { _data = list; _loading = false; });
  }

  Future<void> _submit(String assignmentId) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    final api = ApiClient(context.read<AuthStore>());
    await api.submitAssignment(assignmentId: assignmentId, file: File(path));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Submitted')));
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_data?['rows'] as List<dynamic>?) ?? [];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Text('Assignments', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, i) {
                  final a = rows[i] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(a['title'] as String),
                      subtitle: Text('Due: ${(a['dueAt'] as String).substring(0, 10)}'),
                      trailing: FilledButton(onPressed: () => _submit(a['id'] as String), child: const Text('Submit')),
                    ),
                  );
                },
              ),
      ),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: _page > 1 ? () { setState(() => _page -= 1); _load(); } : null, child: const Text('Prev')),
        Text('Page $_page'),
        TextButton(onPressed: () { setState(() => _page += 1); _load(); }, child: const Text('Next')),
      ]),
      const SizedBox(height: 8),
    ]);
  }
}

