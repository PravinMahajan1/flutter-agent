import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analytics', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _ActionCard(
            title: 'Download Attendance CSV',
            subtitle: 'Export filtered analytics',
            icon: Icons.download,
            onTap: () => launchUrlString('http://localhost:3000/api/analytics/attendance.csv'),
          ),
        ]),
      ]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: SizedBox(
          width: 260,
          height: 140,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 28),
              const Spacer(),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle),
            ]),
          ),
        ),
      ),
    );
  }
}