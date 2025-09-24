import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});
  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  Map<String, dynamic>? _assignments;
  int _page = 1;
  final _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    final list = await api.listAssignments(page: _page, pageSize: _pageSize);
    if (mounted) setState(() => _assignments = list);
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_assignments?['rows'] as List<dynamic>?) ?? [];
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
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rows.length,
          itemBuilder: (context, i) {
            final a = rows[i] as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(a['title'] as String),
                subtitle: Text('Due: ${(a['dueAt'] as String).substring(0, 10)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download submissions from web admin')));
                  },
                ),
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