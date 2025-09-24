import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class QrGeneratePage extends StatefulWidget {
  const QrGeneratePage({super.key});
  @override
  State<QrGeneratePage> createState() => _QrGeneratePageState();
}

class _QrGeneratePageState extends State<QrGeneratePage> {
  List<dynamic>? _subjects;
  String? _subjectId;
  String _type = 'lecture';
  int _duration = 10;
  int? _labNumber;
  String? _batch;
  double? _lat;
  double? _lon;
  int? _radius;
  Map<String, dynamic>? _session;
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ApiClient(context.read<AuthStore>());
    final s = await api.listSubjects();
    setState(() => _subjects = s);
  }

  Future<void> _create() async {
    if (_subjectId == null) return;
    final api = ApiClient(context.read<AuthStore>());
    final session = await api.createAttendanceSession(
      subjectId: _subjectId!,
      type: _type,
      labNumber: _labNumber,
      batch: _batch,
      durationMinutes: _duration,
      latitude: _lat,
      longitude: _lon,
      radiusMeters: _radius,
    );
    setState(() => _session = session);
    _startCountdown(DateTime.parse(session['expiresAt'] as String));
  }

  void _startCountdown(DateTime expires) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final diff = expires.difference(now);
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
      if (diff.isNegative) _timer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjects = _subjects ?? [];
    final isWide = MediaQuery.of(context).size.width > 800;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildForm(subjects)),
                  const SizedBox(width: 24),
                  Expanded(child: _buildPreview()),
                ])
              : Column(children: [
                  _buildForm(subjects),
                  const SizedBox(height: 16),
                  _buildPreview(),
                ]),
        ),
      ),
    );
  }

  Widget _buildForm(List<dynamic> subjects) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Create Attendance Session', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _subjectId,
            items: subjects.map<DropdownMenuItem<String>>((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['name']))).toList(),
            onChanged: (v) => setState(() => _subjectId = v),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            items: const [
              DropdownMenuItem(value: 'lecture', child: Text('Lecture')),
              DropdownMenuItem(value: 'lab', child: Text('Lab')),
              DropdownMenuItem(value: 'library', child: Text('Library')),
            ],
            onChanged: (v) => setState(() => _type = v ?? 'lecture'),
            decoration: const InputDecoration(labelText: 'Type'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                initialValue: '10',
                keyboardType: TextInputType.number,
                onChanged: (v) => _duration = int.tryParse(v) ?? 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Lab number (optional)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _labNumber = int.tryParse(v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Batch (optional)'),
            onChanged: (v) => _batch = v.isEmpty ? null : v,
          ),
          const SizedBox(height: 12),
          Text('Geofencing (optional)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Latitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _lat = double.tryParse(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Longitude'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _lon = double.tryParse(v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Radius (m)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _radius = int.tryParse(v),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _subjectId == null ? null : _create,
              child: const Text('Create session'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildPreview() {
    final token = _session?['qrToken'] as String?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Text('QR Preview', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(_remaining == Duration.zero ? 'Expired' : 'Expires in ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}'),
            ]),
            const SizedBox(height: 16),
            if (token == null)
              const Text('Create a session to preview QR')
            else
              Center(
                child: QrImageView(
                  data: token,
                  size: 260,
                  backgroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}