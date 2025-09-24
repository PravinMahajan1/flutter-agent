import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});
  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<dynamic>? _subjects;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthStore>();
    final api = ApiClient(auth);
    final subjects = await api.listSubjects();
    if (mounted) setState(() => _subjects = subjects);
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects;
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _StatCard(title: 'Attendance', value: '—'),
          _StatCard(title: 'Assignments', value: '—'),
          _StatCard(title: 'Results', value: '—'),
          if (subjects != null)
            ...subjects.map((s) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s['name'], style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Code: ${s['code']}'),
                      Text('Division: ${s['division']}'),
                    ]),
                  ),
                )),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ]),
      ),
    );
  }
}

