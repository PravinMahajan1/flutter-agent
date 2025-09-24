import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class LeavesPage extends StatefulWidget {
  const LeavesPage({super.key});
  @override
  State<LeavesPage> createState() => _LeavesPageState();
}

class _LeavesPageState extends State<LeavesPage> {
  final _reason = TextEditingController();
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 1));
  File? _attachment;
  List<dynamic> _leaves = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    final list = await api.listLeaves();
    if (mounted) setState(() => _leaves = list);
  }

  Future<void> _submit() async {
    final api = ApiClient(context.read<AuthStore>());
    await api.submitLeave(from: _from, to: _to, reason: _reason.text, attachment: _attachment);
    if (!mounted) return;
    _reason.clear();
    _attachment = null;
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave submitted')));
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaWiki of(context).size.width > 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildForm()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildList()),
                ])
              : Column(children: [
                  _buildForm(),
                  const SizedBox(height: 16),
                  _buildList(),
                ]),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Submit Leave', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Reason')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _DateField(label: 'From', value: _from, onPick: (d) => setState(() => _from = d))),
            const SizedBox(width: 12),
            Expanded(child: _DateField(label: 'To', value: _to, onPick: (d) => setState(() => _to = d))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton(
              onPressed: () async {
                final r = await FilePicker.platform.pickFiles();
                if (r != null && r.files.single.path != null) setState(() => _attachment = File(r.files.single.path!));
              },
              child: const Text('Attach file (optional)'),
            ),
            const SizedBox(width: 12),
            Text(_attachment?.path.split('/').last ?? 'No file'),
          ]),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: _submit, child: const Text('Submit'))),
        ]),
      ),
    );
  }

  Widget _buildList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('My Leaves', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._leaves.map((l) => ListTile(
                title: Text('${(l['fromDate'] as String).substring(0, 10)} → ${(l['toDate'] as String).substring(0, 10)}'),
                subtitle: Text(l['reason'] as String),
                trailing: Chip(label: Text(l['status'] as String)),
              )),
        ]),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;
  const _DateField({required this.label, required this.value, required this.onPick});
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: value.toString().substring(0, 10)),
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2020), lastDate: DateTime(2100));
        if (picked != null) onPick(picked);
      },
    );
  }
}

