import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  int _page = 1;
  final int _pageSize = 20;
  List<dynamic> _rows = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient(context.read<AuthStore>());
    final rows = await api.listResults(page: _page, pageSize: _pageSize);
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          Text('Results', style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: isWide ? _buildTable() : _buildList(),
              ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          TextButton(onPressed: _page > 1 ? () { setState(() => _page -= 1); _load(); } : null, child: const Text('Prev')),
          const SizedBox(width: 8),
          Text('Page $_page'),
          const SizedBox(width: 8),
          TextButton(onPressed: () { setState(() => _page += 1); _load(); }, child: const Text('Next')),
        ]),
      ),
    ]);
  }

  Widget _buildTable() {
    return Card(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Subject')),
          DataColumn(label: Text('Exam')),
          DataColumn(label: Text('Marks')),
          DataColumn(label: Text('Grade')),
          DataColumn(label: Text('Date')),
        ],
        rows: _rows
            .map((r) => DataRow(cells: [
                  DataCell(Text(r['subjectId'] as String)),
                  DataCell(Text(r['examType'] as String)),
                  DataCell(Text('${r['marksObtained']}/${r['totalMarks']}')),
                  DataCell(Text((r['grade'] ?? '') as String)),
                  DataCell(Text((r['createdAt'] as String).substring(0, 10))),
                ]))
            .toList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (context, i) {
        final r = _rows[i] as Map<String, dynamic>;
        return Card(
          child: ListTile(
            title: Text('${r['examType']} - ${r['subjectId']}'),
            subtitle: Text('Marks: ${r['marksObtained']}/${r['totalMarks']}'),
            trailing: Text((r['grade'] ?? '') as String),
          ),
        );
      },
    );
  }
}