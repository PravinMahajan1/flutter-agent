import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/api_client.dart';
import '../services/auth_store.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture cap) async {
    if (_processing) return;
    final code = cap.barcodes.first.rawValue;
    if (code == null) return;
    setState(() => _processing = true);
    try {
      Position? pos;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        var permission = await Geolocator.checkPermission();
        if (!serviceEnabled || permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          pos = await Geolocator.getCurrentPosition();
        }
      } catch (_) {}
      final auth = context.read<AuthStore>();
      final api = ApiClient(auth);
      await api.scanAttendance(token: code, lat: pos?.latitude, lon: pos?.longitude);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const SizedBox(height: 8),
      const Text('Scan QR to mark attendance'),
      const SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: MobileScanner(onDetect: _onDetect),
          ),
        ),
      ),
    ]);
  }
}

