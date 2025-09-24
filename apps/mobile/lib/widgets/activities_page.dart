import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class ActivitiesPage extends StatefulWidget {
  const ActivitiesPage({super.key});
  @override
  State<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends State<ActivitiesPage> {
  List<dynamic> _activities = [];
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient(context.read<AuthStore>());
    final list = await api.listActivities();
    if (!mounted) return;
    setState(() { _activities = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Text('Activities', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _activities.length,
                itemBuilder: (context, i) {
                  final a = _activities[i] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text(a['title'] as String),
                      subtitle: Text((a['description'] ?? '') as String),
                      trailing: Wrap(spacing: 8, children: [
                        FilledButton(onPressed: () async { await ApiClient(context.read<AuthStore>()).joinActivity(a['id'] as String); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined'))); }, child: const Text('Join')),
                        OutlinedButton(onPressed: () async { final url = await ApiClient(context.read<AuthStore>()).getActivityCertificateUrl(a['id'] as String); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url ?? 'No certificate'))); }, child: const Text('Certificate')),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

